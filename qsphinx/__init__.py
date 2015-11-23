from domain import QDomain
from addnodes import desc_qparameterlist
from writer import QHTMLTranslator
from sphinx.writers.latex import LaTeXTranslator
from sphinx.writers.text import TextTranslator

def setup(app):
    app.add_domain(QDomain)

    app.add_node(
    	node = desc_qparameterlist,
    	latex = (LaTeXTranslator.visit_desc_parameterlist,LaTeXTranslator.depart_desc_parameterlist),
    	text = (TextTranslator.visit_desc_parameterlist,TextTranslator.depart_desc_parameterlist)
	)

    app.set_translator('html', QHTMLTranslator)