from sphinx.writers.html import HTMLTranslator, HTMLWriter
from sphinx import addnodes

class QHTMLWriter(HTMLWriter):
    """
    This docutils writer will use the QHTMLTranslator class below.

    """
    def __init__(self):
        HTMLWriter.__init__(self)
        self.translator_class = QHTMLTranslator

class QHTMLTranslator(HTMLTranslator):
    """
    This is a translator class for the docutils system.
    It allows the use of bracket rather than parentheses for Q functions.
    """
    def visit_desc_qparameterlist(self, node):
        self.body.append('<span class="sig-paren">[</span>')
        self.first_param = 1
        self.optional_param_level = 0
        # How many required parameters are left.
        self.required_params_left = sum([isinstance(c, addnodes.desc_parameter)
                                         for c in node.children])
        self.param_separator = node.child_text_separator

    def depart_desc_qparameterlist(self, node):
        self.body.append('<span class="sig-paren">]</span>')
