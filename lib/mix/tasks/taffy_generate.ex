defmodule Mix.Tasks.Taffy.Generate do
  @moduledoc """
  Generate ExUnit tests from Taffy flex test fixtures.

  Parses the machine-generated Rust test files (border_box variant only)
  and produces categorized Elixir test modules.

      mix taffy.generate
      mix taffy.generate --source /path/to/taffy/tests/generated/flex
  """
  use Mix.Task

  @shortdoc "Generate ExUnit tests from Taffy flex fixtures"

  @default_source "/tmp/taffy/tests/generated/flex"
  @output_dir "test/courgette/layout/engine/taffy"

  # Unsupported features that cause a test to be tagged @tag :skip
  @unsupported_patterns [
    {~r/Position::Absolute/, "absolute positioning"},
    {~r/from_percent\((?!0f32)/, "percentage dimensions"},
    {~r/aspect_ratio:\s*Some/, "aspect_ratio"},
    {~r/FlexDirection::RowReverse/, "row_reverse"},
    {~r/FlexDirection::ColumnReverse/, "column_reverse"},
    {~r/FlexWrap::WrapReverse/, "wrap_reverse"},
    {~r/new_leaf_with_context/, "measure function"},
    {~r/Display::None/, "display_none"},
    {~r/Display::Grid/, "display_grid"},
    {~r/Display::Block/, "display_block"},
    {~r/Overflow::Scroll/, "overflow_scroll"},
    {~r/LengthPercentageAuto::AUTO/, "auto margins"},
    {~r/inset:/, "insets"},
    {~r/percent\((?!0f32)/, "percentage values"},
    {~r/AlignItems::Baseline/, "baseline alignment"},
    {~r/AlignSelf::Baseline/, "baseline alignment"},
    {~r/BoxSizing::ContentBox/, "content-box sizing"}
  ]

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [source: :string])
    source_dir = opts[:source] || @default_source

    unless File.dir?(source_dir) do
      Mix.raise("Source directory not found: #{source_dir}")
    end

    files = Path.wildcard(Path.join(source_dir, "*.rs")) |> Enum.sort()
    Mix.shell().info("Found #{length(files)} Taffy fixture files")

    results =
      files
      |> Enum.map(&parse_file/1)
      |> Enum.reject(&is_nil/1)

    Mix.shell().info("Successfully parsed #{length(results)} tests")

    # Group by category
    grouped = Enum.group_by(results, fn {_name, _test, category, _skip} -> category end)

    # Ensure output directory exists
    File.mkdir_p!(@output_dir)

    # Generate one test file per category
    Enum.each(grouped, fn {category, tests} ->
      content = generate_test_file(category, tests)
      path = Path.join(@output_dir, "#{category}_test.exs")
      File.write!(path, content)

      skip_count = Enum.count(tests, fn {_, _, _, skip} -> skip != nil end)
      active = length(tests) - skip_count
      Mix.shell().info("  #{path}: #{length(tests)} tests (#{active} active, #{skip_count} skipped)")
    end)

    total_skip = Enum.count(results, fn {_, _, _, skip} -> skip != nil end)
    total_active = length(results) - total_skip
    Mix.shell().info("\nTotal: #{length(results)} tests (#{total_active} active, #{total_skip} skipped)")
  end

  # --- File Parsing ---

  defp parse_file(path) do
    content = File.read!(path)
    test_name = Path.basename(path, ".rs")

    case extract_border_box(content) do
      nil ->
        Mix.shell().info("  SKIP (no border_box): #{test_name}")
        nil

      body ->
        skip_reasons = detect_unsupported(body)
        category = categorize(test_name)

        case parse_test(test_name, body) do
          {:ok, test_code} ->
            skip = if skip_reasons == [], do: nil, else: Enum.join(skip_reasons, ", ")
            {test_name, test_code, category, skip}

          {:error, reason} ->
            Mix.shell().info("  SKIP (parse error: #{reason}): #{test_name}")
            nil
        end
    end
  end

  defp extract_border_box(content) do
    # Find the __border_box function and extract its body
    case Regex.run(~r/fn \w+__border_box\(\)\s*\{(.+?)^\}/ms, content) do
      [_, body] -> body
      nil -> nil
    end
  end

  defp detect_unsupported(body) do
    Enum.flat_map(@unsupported_patterns, fn {pattern, reason} ->
      if Regex.match?(pattern, body), do: [reason], else: []
    end)
  end

  defp categorize(name) do
    cond do
      String.starts_with?(name, "wrap_") or String.starts_with?(name, "flex_wrap") -> "wrap"
      String.starts_with?(name, "align_") -> "align"
      String.starts_with?(name, "flex_") -> "flex"
      String.starts_with?(name, "justify_") -> "justify"
      String.starts_with?(name, "gap_") -> "gap"
      String.match?(name, ~r/^(padding|border|margin|min_|max_|size_)/) -> "sizing"
      true -> "misc"
    end
  end

  # --- Test Parsing ---

  defp parse_test(test_name, body) do
    with {:ok, nodes} <- parse_nodes(body),
         {:ok, root_name, tree} <- build_tree(nodes),
         {:ok, assertions} <- parse_assertions(body) do
      test_code = generate_test(test_name, nodes, root_name, tree, assertions)
      {:ok, test_code}
    end
  end

  # Parse all node definitions from the border_box body
  defp parse_nodes(body) do
    # Split at "let " boundaries to find each node definition
    # Pattern: let nodeXX = taffy\n  .new_leaf(...) or .new_with_children(...)
    node_pattern =
      ~r/let\s+(node\w*)\s*=\s*taffy\s*(?:\n\s*)?\.\s*(new_leaf|new_with_children|new_leaf_with_context)\s*\(/

    # Find all node definition start positions
    matches = Regex.scan(node_pattern, body, return: :index)
    names = Regex.scan(node_pattern, body)

    if names == [] do
      {:error, "no nodes found"}
    else
      nodes =
        names
        |> Enum.with_index()
        |> Enum.map(fn {[_full, var_name, node_type], idx} ->
          # Extract the full node definition text (from "let" to ".unwrap();")
          [{start, _} | _] = Enum.at(matches, idx)
          rest = String.slice(body, start, String.length(body))
          node_text = extract_until_unwrap(rest)

          style = parse_style(node_text)
          children = parse_children(node_text, node_type)
          {var_name, %{style: style, children: children, type: node_type}}
        end)

      {:ok, Map.new(nodes)}
    end
  end

  # Extract text from start until ".unwrap();"
  defp extract_until_unwrap(text) do
    case String.split(text, ".unwrap();", parts: 2) do
      [before, _] -> before
      _ -> text
    end
  end

  defp parse_children(text, "new_with_children") do
    case Regex.run(~r/&\[([\w\s,]+)\]/, text) do
      [_, children_str] ->
        children_str
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))

      nil ->
        []
    end
  end

  defp parse_children(_text, _), do: []

  # Parse style properties from a node definition
  defp parse_style(text) do
    props = %{}

    props = parse_flex_grow(text, props)
    props = parse_flex_shrink(text, props)
    props = parse_flex_basis(text, props)
    props = parse_flex_direction(text, props)
    props = parse_flex_wrap(text, props)
    props = parse_size(text, props, "size", "width", "height")
    props = parse_size(text, props, "min_size", "min_width", "min_height")
    props = parse_size(text, props, "max_size", "max_width", "max_height")
    props = parse_align_items(text, props)
    props = parse_align_self(text, props)
    props = parse_align_content(text, props)
    props = parse_justify_content(text, props)
    props = parse_gap(text, props)
    props = parse_rect(text, props, "padding", "padding")
    props = parse_rect(text, props, "border", "border")
    props = parse_rect(text, props, "margin", "margin")
    props = parse_overflow(text, props)

    props
  end

  defp parse_flex_grow(text, props) do
    case Regex.run(~r/flex_grow:\s*(\d+(?:\.\d+)?)f32/, text) do
      [_, val] ->
        v = parse_number(val)
        if v != 0, do: Map.put(props, :flex_grow, v), else: props

      nil ->
        props
    end
  end

  defp parse_flex_shrink(text, props) do
    case Regex.run(~r/flex_shrink:\s*(\d+(?:\.\d+)?)f32/, text) do
      [_, val] ->
        v = parse_number(val)
        # Default flex_shrink is 1 in CSS, so only emit if different
        if v != 1, do: Map.put(props, :flex_shrink, v), else: props

      nil ->
        props
    end
  end

  defp parse_flex_basis(text, props) do
    cond do
      match = Regex.run(~r/flex_basis:\s*taffy::style::Dimension::from_length\((\d+(?:\.\d+)?)f32\)/, text) ->
        [_, val] = match
        Map.put(props, :flex_basis, parse_number(val))

      Regex.match?(~r/flex_basis:\s*taffy::style::Dimension::from_percent\(0f32\)/, text) ->
        # 0% is effectively 0
        Map.put(props, :flex_basis, 0)

      true ->
        props
    end
  end

  defp parse_flex_direction(text, props) do
    case Regex.run(~r/flex_direction:\s*taffy::style::FlexDirection::(\w+)/, text) do
      [_, "Column"] -> Map.put(props, :flex_direction, :column)
      [_, "Row"] -> props  # Row is default
      _ -> props
    end
  end

  defp parse_flex_wrap(text, props) do
    case Regex.run(~r/flex_wrap:\s*taffy::style::FlexWrap::(\w+)/, text) do
      [_, "Wrap"] -> Map.put(props, :flex_wrap, :wrap)
      _ -> props
    end
  end

  defp parse_size(text, props, rust_field, w_key, h_key) do
    # Match: field: taffy::geometry::Size { width: ..., height: ... }
    # Use negative lookbehind to avoid matching "max_size" when looking for "size"
    pattern =
      ~r/(?<![_a-z])#{rust_field}:\s*taffy::geometry::Size\s*\{\s*width:\s*(.+?),\s*height:\s*(.+?)\s*\}/s

    case Regex.run(pattern, text) do
      [_, w_text, h_text] ->
        props = maybe_put_dimension(props, String.to_atom(w_key), w_text)
        maybe_put_dimension(props, String.to_atom(h_key), h_text)

      nil ->
        props
    end
  end

  defp maybe_put_dimension(props, key, dim_text) do
    dim_text = String.trim(dim_text)

    cond do
      String.contains?(dim_text, "from_length") ->
        case Regex.run(~r/from_length\((\d+(?:\.\d+)?)f32\)/, dim_text) do
          [_, val] -> Map.put(props, key, parse_number(val))
          nil -> props
        end

      String.contains?(dim_text, "auto") ->
        props

      true ->
        props
    end
  end

  defp parse_align_items(text, props) do
    case Regex.run(~r/align_items:\s*Some\(taffy::style::AlignItems::(\w+)\)/, text) do
      [_, variant] -> Map.put(props, :align_items, map_align_variant(variant))
      nil -> props
    end
  end

  defp parse_align_self(text, props) do
    case Regex.run(~r/align_self:\s*Some\(taffy::style::AlignSelf::(\w+)\)/, text) do
      [_, variant] -> Map.put(props, :align_self, map_align_variant(variant))
      nil -> props
    end
  end

  defp parse_align_content(text, props) do
    case Regex.run(~r/align_content:\s*Some\(taffy::style::AlignContent::(\w+)\)/, text) do
      [_, variant] -> Map.put(props, :align_content, map_align_variant(variant))
      nil -> props
    end
  end

  defp parse_justify_content(text, props) do
    case Regex.run(~r/justify_content:\s*Some\(taffy::style::JustifyContent::(\w+)\)/, text) do
      [_, variant] -> Map.put(props, :justify_content, map_justify_variant(variant))
      nil -> props
    end
  end

  defp map_align_variant("FlexStart"), do: :flex_start
  defp map_align_variant("FlexEnd"), do: :flex_end
  defp map_align_variant("Center"), do: :center
  defp map_align_variant("Stretch"), do: :stretch
  defp map_align_variant("Baseline"), do: :baseline
  defp map_align_variant("Start"), do: :flex_start
  defp map_align_variant("End"), do: :flex_end
  defp map_align_variant("SpaceBetween"), do: :space_between
  defp map_align_variant("SpaceAround"), do: :space_around
  defp map_align_variant("SpaceEvenly"), do: :space_evenly
  defp map_align_variant(other), do: String.to_atom(Macro.underscore(other))

  defp map_justify_variant("FlexStart"), do: :flex_start
  defp map_justify_variant("FlexEnd"), do: :flex_end
  defp map_justify_variant("Center"), do: :center
  defp map_justify_variant("SpaceBetween"), do: :space_between
  defp map_justify_variant("SpaceAround"), do: :space_around
  defp map_justify_variant("SpaceEvenly"), do: :space_evenly
  defp map_justify_variant("Start"), do: :flex_start
  defp map_justify_variant("End"), do: :flex_end
  defp map_justify_variant(other), do: String.to_atom(Macro.underscore(other))

  defp parse_overflow(text, props) do
    if Regex.match?(~r/Overflow::Hidden/, text) do
      Map.put(props, :overflow, :hidden)
    else
      props
    end
  end

  defp parse_gap(text, props) do
    case Regex.run(~r/gap:\s*taffy::geometry::Size\s*\{\s*width:\s*(.+?)\s*,\s*height:\s*(.+?)\s*\}/, text) do
      [_, col_text, row_text] ->
        cg = parse_gap_value(col_text)
        rg = parse_gap_value(row_text)

        if cg == 0 and rg == 0 do
          props
        else
          # In Taffy: gap.width = column gap (horizontal), gap.height = row gap (vertical)
          # For row direction: gap_main = column gap, gap_cross = row gap
          # For column direction: gap_main = row gap, gap_cross = column gap
          direction = Map.get(props, :flex_direction, :row)

          if cg == rg do
            Map.put(props, :gap, cg)
          else
            {main, cross} =
              case direction do
                :column -> {rg, cg}
                _row -> {cg, rg}
              end

            props
            |> then(fn p -> if main > 0, do: Map.put(p, :gap_main, main), else: p end)
            |> then(fn p -> if cross > 0, do: Map.put(p, :gap_cross, cross), else: p end)
          end
        end

      nil ->
        props
    end
  end

  defp parse_gap_value(text) do
    text = String.trim(text)

    cond do
      match = Regex.run(~r/length\((\d+(?:\.\d+)?)f32\)/, text) ->
        [_, val] = match
        parse_number(val)

      String.contains?(text, "zero()") ->
        0

      true ->
        0
    end
  end

  defp parse_rect(text, props, rust_field, prefix) do
    # Match both inline and multi-line Rect formats
    pattern =
      ~r/#{rust_field}:\s*taffy::geometry::Rect\s*\{\s*left:\s*(.+?)\s*,\s*right:\s*(.+?)\s*,\s*top:\s*(.+?)\s*,\s*bottom:\s*(.+?)\s*\}/s

    case Regex.run(pattern, text) do
      [_, left, right, top, bottom] ->
        l = parse_rect_value(left)
        r = parse_rect_value(right)
        t = parse_rect_value(top)
        b = parse_rect_value(bottom)

        case prefix do
          "border" ->
            # Fold border into padding values
            # If all sides are 1, map to border: :single
            if l == 1 and r == 1 and t == 1 and b == 1 do
              Map.put(props, :border, :single)
            else
              # Add border values to existing padding
              add_border_to_padding(props, l, r, t, b)
            end

          "margin" ->
            # Only emit length margins (auto margins flagged as unsupported)
            props
            |> maybe_put_nonzero(String.to_atom("margin_left"), l)
            |> maybe_put_nonzero(String.to_atom("margin_right"), r)
            |> maybe_put_nonzero(String.to_atom("margin_top"), t)
            |> maybe_put_nonzero(String.to_atom("margin_bottom"), b)

          "padding" ->
            # Check if all sides are equal
            if l == r and r == t and t == b and l != nil and l > 0 do
              Map.put(props, :padding, l)
            else
              props
              |> maybe_put_nonzero(:padding_left, l)
              |> maybe_put_nonzero(:padding_right, r)
              |> maybe_put_nonzero(:padding_top, t)
              |> maybe_put_nonzero(:padding_bottom, b)
            end
        end

      nil ->
        props
    end
  end

  defp parse_rect_value(text) do
    text = String.trim(text)

    cond do
      match = Regex.run(~r/length\((\d+(?:\.\d+)?)f32\)/, text) ->
        [_, val] = match
        parse_number(val)

      String.contains?(text, "zero()") ->
        0

      true ->
        nil
    end
  end

  defp add_border_to_padding(props, l, r, t, b) do
    # If there's already a uniform padding, expand it
    case Map.get(props, :padding) do
      nil ->
        pl = Map.get(props, :padding_left, 0)
        pr = Map.get(props, :padding_right, 0)
        pt = Map.get(props, :padding_top, 0)
        pb = Map.get(props, :padding_bottom, 0)

        props
        |> Map.delete(:padding)
        |> maybe_put_nonzero(:padding_left, (l || 0) + pl)
        |> maybe_put_nonzero(:padding_right, (r || 0) + pr)
        |> maybe_put_nonzero(:padding_top, (t || 0) + pt)
        |> maybe_put_nonzero(:padding_bottom, (b || 0) + pb)

      uniform ->
        new_l = (l || 0) + uniform
        new_r = (r || 0) + uniform
        new_t = (t || 0) + uniform
        new_b = (b || 0) + uniform

        if new_l == new_r and new_r == new_t and new_t == new_b do
          Map.put(props, :padding, new_l)
        else
          props
          |> Map.delete(:padding)
          |> maybe_put_nonzero(:padding_left, new_l)
          |> maybe_put_nonzero(:padding_right, new_r)
          |> maybe_put_nonzero(:padding_top, new_t)
          |> maybe_put_nonzero(:padding_bottom, new_b)
        end
    end
  end

  defp maybe_put_nonzero(props, _key, nil), do: props
  defp maybe_put_nonzero(props, _key, 0), do: props
  defp maybe_put_nonzero(props, _key, +0.0), do: props
  defp maybe_put_nonzero(props, key, val), do: Map.put(props, key, val)

  # --- Tree Building ---

  defp build_tree(nodes) do
    # The root is the node named "node" (no digit suffix)
    root_name =
      nodes
      |> Map.keys()
      |> Enum.find(fn k -> k == "node" end)

    case root_name do
      nil -> {:error, "no root node found"}
      name -> {:ok, name, build_parent_map(nodes)}
    end
  end

  # Build a map of child_name => {parent_name, index}
  defp build_parent_map(nodes) do
    Enum.flat_map(nodes, fn {parent_name, %{children: children}} ->
      children
      |> Enum.with_index()
      |> Enum.map(fn {child_name, idx} -> {child_name, {parent_name, idx}} end)
    end)
    |> Map.new()
  end

  # Get the path from root to a node as a list of child indices
  defp node_path("node", _parent_map), do: []

  defp node_path(name, parent_map) do
    case Map.get(parent_map, name) do
      {parent, idx} -> node_path(parent, parent_map) ++ [idx]
      nil -> []
    end
  end

  # --- Assertion Parsing ---

  defp parse_assertions(body) do
    # Pattern: let layout = taffy.layout(nodeXX).unwrap();
    # followed by let Layout { size, location, .. } = layout;
    # followed by assert_eq! lines
    chunks =
      Regex.split(~r/let layout = taffy\.layout\(/, body)
      |> Enum.drop(1)

    assertions =
      Enum.map(chunks, fn chunk ->
        # Extract node name
        [node_name | _] = String.split(chunk, ")", parts: 2)
        node_name = String.trim(node_name)

        # Extract assertion values
        w = extract_assert_value(chunk, "size.width")
        h = extract_assert_value(chunk, "size.height")
        x = extract_assert_value(chunk, "location.x")
        y = extract_assert_value(chunk, "location.y")

        {node_name, %{w: w, h: h, x: x, y: y}}
      end)

    {:ok, assertions}
  end

  defp extract_assert_value(text, field) do
    case Regex.run(~r/assert_eq!\(#{Regex.escape(field)},\s*(-?\d+(?:\.\d+)?)f32/, text) do
      [_, val] -> parse_number(val)
      nil -> 0
    end
  end

  # --- Code Generation ---

  defp generate_test(test_name, nodes, root_name, parent_map, assertions) do
    root = Map.get(nodes, root_name)
    root_style = root.style
    avail_w = Map.get(root_style, :width)
    avail_h = Map.get(root_style, :height)

    avail_w_str = if avail_w, do: "#{format_float(avail_w)}", else: "nil"
    avail_h_str = if avail_h, do: "#{format_float(avail_h)}", else: "nil"

    el_code = generate_element(root_name, nodes, 6)
    assertion_code = generate_assertion_code(assertions, parent_map)

    """
      describe "#{test_name}" do
        test "border_box" do
          el = #{el_code}
          r = Flex.layout(el, %{width: #{avail_w_str}, height: #{avail_h_str}})
    #{assertion_code}\
        end
      end
    """
  end

  defp generate_element(node_name, nodes, indent) do
    node = Map.get(nodes, node_name)
    pad = String.duplicate(" ", indent)

    case node.children do
      [] ->
        props = format_props(node.style, false)

        if props == "" do
          "box([])"
        else
          "box(#{props})"
        end

      children ->
        props = format_props(node.style, true)

        children_code =
          children
          |> Enum.map(&generate_element(&1, nodes, indent + 2))
          |> Enum.join(",\n#{pad}  ")

        if props == "" do
          "box([], [\n#{pad}  #{children_code}\n#{pad}])"
        else
          "box(#{props}, [\n#{pad}  #{children_code}\n#{pad}])"
        end
    end
  end

  defp format_props(style, _has_children) when map_size(style) == 0, do: ""

  defp format_props(style, has_children) do
    # Order props consistently
    ordered_keys = [
      :width,
      :height,
      :min_width,
      :min_height,
      :max_width,
      :max_height,
      :flex_direction,
      :flex_wrap,
      :flex_grow,
      :flex_shrink,
      :flex_basis,
      :align_items,
      :align_self,
      :align_content,
      :justify_content,
      :gap,
      :gap_main,
      :gap_cross,
      :padding,
      :padding_left,
      :padding_right,
      :padding_top,
      :padding_bottom,
      :margin_left,
      :margin_right,
      :margin_top,
      :margin_bottom,
      :border,
      :overflow
    ]

    props =
      ordered_keys
      |> Enum.filter(&Map.has_key?(style, &1))
      |> Enum.map(fn key ->
        val = Map.get(style, key)
        "#{key}: #{format_value(val)}"
      end)
      |> Enum.join(", ")

    # Leaf nodes with a single prop can use bare keyword syntax: box(flex_grow: 1)
    # Parent nodes MUST bracket props: box([flex_grow: 1], [children...])
    if not has_children and map_size(style) == 1 do
      props
    else
      "[#{props}]"
    end
  end

  defp format_value(val) when is_atom(val), do: ":#{val}"
  defp format_value(val) when is_integer(val), do: "#{val}"

  defp format_value(val) when is_float(val) do
    if val == Float.round(val), do: "#{trunc(val)}", else: "#{val}"
  end

  defp generate_assertion_code(assertions, parent_map) do
    # Collect all paths and figure out which intermediate vars we need
    assertion_entries =
      Enum.map(assertions, fn {node_name, values} ->
        path = node_path(node_name, parent_map)
        {node_name, path, values}
      end)

    # Sort by path depth (root first)
    assertion_entries = Enum.sort_by(assertion_entries, fn {_, path, _} -> length(path) end)

    # Track which intermediate variables we've declared
    {lines, _declared} =
      Enum.reduce(assertion_entries, {[], MapSet.new()}, fn {_name, path, values}, {lines, declared} ->
        {accessor, new_lines, declared} = build_accessor(path, declared)
        assertion = "      assert_layout(#{accessor}, %{w: #{format_num(values.w)}, h: #{format_num(values.h)}, x: #{format_num(values.x)}, y: #{format_num(values.y)}})"
        {lines ++ new_lines ++ [assertion], declared}
      end)

    Enum.join(lines, "\n") <> "\n"
  end

  # Build the accessor expression for a node path, creating intermediate
  # variables as needed. Returns {accessor_str, new_lines, updated_declared}
  defp build_accessor([], declared), do: {"r", [], declared}

  defp build_accessor([idx], declared) do
    {"child(r, #{idx})", [], declared}
  end

  defp build_accessor(path, declared) do
    # For deep paths, we need intermediate variables
    # e.g., path [0, 1] needs: c0 = child(r, 0); then child(c0, 1)
    # path [0, 1, 2] needs: c0, c01, then child(c01, 2)
    {new_lines, declared} = ensure_intermediates(path, declared)
    accessor = path_accessor(path)
    {accessor, new_lines, declared}
  end

  defp ensure_intermediates(path, declared) do
    # For path [a, b, c], we need vars for [a] and [a, b]
    prefixes =
      1..(length(path) - 1)
      |> Enum.map(&Enum.take(path, &1))

    Enum.reduce(prefixes, {[], declared}, fn prefix, {lines, declared} ->
      var = path_var(prefix)

      if MapSet.member?(declared, var) do
        {lines, declared}
      else
        parent_accessor =
          case prefix do
            [idx] -> "child(r, #{idx})"
            _ -> "child(#{path_var(Enum.drop(prefix, -1))}, #{List.last(prefix)})"
          end

        line = "      #{var} = #{parent_accessor}"
        {lines ++ [line], MapSet.put(declared, var)}
      end
    end)
  end

  defp path_var(indices), do: "c" <> Enum.join(indices, "")

  defp path_accessor([idx]), do: "child(r, #{idx})"

  defp path_accessor(path) do
    parent_var = path_var(Enum.drop(path, -1))
    "child(#{parent_var}, #{List.last(path)})"
  end

  # --- Test File Generation ---

  defp generate_test_file(category, tests) do
    module_name = String.capitalize(category)

    test_bodies =
      tests
      |> Enum.sort_by(fn {name, _, _, _} -> name end)
      |> Enum.map(fn {_name, code, _, skip} ->
        if skip do
          # Put @tag :skip inside the describe block, before the test
          code_with_tag =
            String.replace(code, "    test \"border_box\" do", "    # Unsupported: #{skip}\n    @tag :skip\n    test \"border_box\" do")

          code_with_tag
        else
          code
        end
      end)
      |> Enum.join("\n")

    """
    defmodule Courgette.Layout.Engine.Taffy.#{module_name}Test do
      @moduledoc "Auto-generated from Taffy border_box fixtures. DO NOT EDIT."
      use ExUnit.Case, async: true

      alias Courgette.Element
      alias Courgette.Layout.Engine.Flex

      defp box(props, children \\\\ []), do: Element.new(:box, props, children)

      defp assert_layout(result, expected) do
        assert_in_delta result.width, expected.w, 0.5,
          "width: expected \#{expected.w}, got \#{result.width}"
        assert_in_delta result.height, expected.h, 0.5,
          "height: expected \#{expected.h}, got \#{result.height}"
        assert_in_delta result.x, expected.x, 0.5,
          "x: expected \#{expected.x}, got \#{result.x}"
        assert_in_delta result.y, expected.y, 0.5,
          "y: expected \#{expected.y}, got \#{result.y}"
      end

      defp child(result, idx), do: Enum.at(result.children, idx)

    #{test_bodies}end
    """
  end

  # --- Helpers ---

  defp parse_number(str) do
    str = String.trim(str)

    if String.contains?(str, ".") do
      {f, _} = Float.parse(str)
      if f == Float.round(f), do: trunc(f), else: f
    else
      String.to_integer(str)
    end
  end

  defp format_num(val) when is_integer(val), do: "#{val}"
  defp format_num(val) when is_float(val) do
    if val == Float.round(val), do: "#{trunc(val)}", else: "#{val}"
  end

  defp format_float(val) when is_integer(val), do: "#{val}.0"
  defp format_float(val) when is_float(val), do: "#{val}"
end
