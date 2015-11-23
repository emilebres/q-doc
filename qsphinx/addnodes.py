from docutils import nodes

class desc_qparameterlist(nodes.Part, nodes.Inline, nodes.TextElement):
    """Node for a Q parameter list."""
    child_text_separator = '; '