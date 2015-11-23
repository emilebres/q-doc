# -*- coding: utf-8 -*-
"""
    sphinxcontrib.qdomain
    ~~~~~~~~~~~~~~~~~~~~~~~~~

    The Sphinx domain for documenting Q APIs.

    :copyright: (c) 2012 by Georges Discry.
    :license: BSD, see LICENSE for more details.
"""

__version__ = '0.1'
__release__ = '0.1a1'

from docutils import nodes
from docutils.parsers.rst import directives

from sphinx import addnodes
from sphinx.directives import ObjectDescription
from sphinx.domains import Domain, ObjType, Index
from sphinx.roles import XRefRole
from sphinx.util.docfields import Field, GroupedField, TypedField
from sphinx.util.compat import Directive
from sphinx.util.nodes import make_refnode

class QFunction(Directive):
    """Directive to mark description of a new function."""

    has_content = False
    required_arguments = 1
    optional_arguments = 0
    final_argument_whitespace = False
    option_spec = {
        'platform': lambda x: x,
        'synopsis': lambda x: x,
        'noindex': directives.flag,
        'deprecated': directives.flag,
    }

    def run(self):
        env = self.state.document.settings.env
        funcname = self.arguments[0].strip()
        noindex = 'noindex' in self.options
        env.temp_data['q:function'] = funcname
        if noindex:
            return []
        env.domaindata['q']['functions'][funcname] = \
            (env.docname, self.options.get('synopsis', ''),
             self.options.get('platform', ''), 'deprecated' in
             self.options)
        # Make a duplicate entry in 'objects' to facilitate searching for the
        # function in QDomain.find_obj()
        env.domaindata['q']['objects'][funcname] = \
            (env.docname, 'function')
        targetnode = nodes.target(ids=['function-' + funcname])
        self.state.document.note_explicit_target(targetnode)
        indextext = '%s (function)' % funcname
        inode = addnodes.index(entries=[('single', indextext,
                                         'function-' + funcname, '')])
        return [targetnode, inode]


class QCurrentFunction(Directive):
    """Directive to mark the description of the content of a function, but
    the links to the function won't lead here.
    """

    has_content = False
    required_arguments = 1
    optional_arguments = 0
    final_argument_whitespace = False
    option_spec = {}

    def run(self):
        env = self.state.document.settings.env
        funcname = self.arguments[0].strip()
        if funcname == 'None':
            env.temp_data['q:function'] = None
        else:
            env.temp_data['q:function'] = funcname
        return []


class QXRefRole(XRefRole):
    """Q cross-referencing role."""

    def process_link(self, env, refnode, has_explicit_title, title, target):
        refnode['q:function'] = env.temp_data.get('q:function')
        if not has_explicit_title:
            title = title.lstrip('.') # Only has a meaning for the target
            target = target.lstrip('~') # Only has a meaning for the title
            # If the first character is a tilde, don't display the function part
            # of the contents
            if title[0:1] == '~':
                title = title[1:]
                dot = title.rfind('.')
                if dot != -1:
                    title = title[dot+1:]
        # If the first character is a dot, search more specific namespaces
        # first, else search builtins first
        if target[0:1] == '.':
            target = target[1:]
            refnode['refspecific'] = True
        return title, target


class QFunctionIndex(Index):
    """Index subclass to provide the Q function index."""

    name = 'funcindex'
    localname = 'Q Function Index'
    shortname = 'functions'

    def generate(self, docnames=None):
        content = {}
        # List of prefixes to ignore
        ignores = self.domain.env.config['qdomain_funcindex_common_prefix']
        ignores = sorted(ignores, key=len, reverse=True)
        # List of all functions, sorted by name
        functions = sorted(self.domain.data['functions'].iteritems(),
                          key=lambda x: x[0].lower())
        # Sort out collapsable functions
        prev_funcname = ''
        num_toplevels = 0
        for funcname, (docname, synopsis, platforms, deprecated) in functions:
            if docnames and docname not in docnames:
                continue

            for ignore in ignores:
                if funcname.startswith(ignore):
                    funcname = funcname[len(ignore):]
                    stripped = ignore
                    break
            else:
                stripped = ''
            # The whole function name was stripped
            if not funcname:
                funcname, stripped = stripped, ''

            entries = content.setdefault(funcname[0].lower(), [])

            parent = funcname.split('.')[0]
            if parent != funcname:
                # It's a child function
                if prev_funcname == parent:
                    # First children function -- make parent a group head
                    if entries:
                        entries[-1][1] = 1
                elif not prev_funcname.startswith(parent):
                    # Orphan function, add dummy entry
                    entries.append([stripped + parent, 1, '', '', '', '', ''])
                subtype = 2
            else:
                num_toplevels += 1
                subtype = 0

            qualifier = 'Deprecated' if deprecated else ''
            entries.append([stripped + funcname, subtype, docname,
                        'function-' + stripped + funcname, platforms, qualifier,
                        synopsis])
            prev_funcname = funcname
        # Collapse only if the number of top-level functions is larger than the
        # number of sub-functions
        collapse = len(functions) - num_toplevels < num_toplevels
        # Sort by first letter
        content = sorted(content.iteritems())

        return content, collapse


class QDomain(Domain):
    """Q language domain."""

    name = 'q'
    label = 'Q'
    object_types = {
        'function': ObjType('function', 'func'),
    }
    directives = {
        'function': QFunction,
        'currentfunction': QCurrentFunction,
    }
    roles = {
        'func': QXRefRole(),
    }
    initial_data = {
        'objects': {},
        'functions': {},
    }
    indices = [
        QFunctionIndex,
    ]

    def clear_doc(self, docname):
        for fullname, (fn, _) in self.data['objects'].items():
            if fn == docname:
                del self.data['objects'][fullname]
        for funcname, (fn, _, _, _) in self.data['functions'].items():
            if fn == docname:
                del self.data['functions'][funcname]

    def find_obj(self, env, funcname, name, type, searchmode=0):
        """Find a Q object for "name", perhaps using the given function.
        Returns a list of (name, object entry) tuples.
        """

        if not name:
            return []

        objects = self.data['objects']
        matches = []

        newname = None
        if searchmode == 1:
            objtypes = self.objtypes_for_role(type)
            if objtypes is not None:
                if funcname and funcname + '.' + name in objects and \
                   objects[funcname + '.' + name][1] in objtypes:
                    newname = funcname + '.' + name
                elif name in objects and objects[name][1] in objtypes:
                    newname = name
                else:
                    searchname = '.' + name
                    matches = [(oname, objects[oname]) for oname in objects
                               if oname.endswith(searchname)
                               and objects[oname][1] in objtypes]
        else:
            # NOTE: Searching for exact match, object type not considered
            if name in objects:
                newname = name
            elif type == 'func':
                return []
            elif funcname and funcname + '.' + name in objects:
                newname = funcname + '.' + name
        if newname is not None:
            matches.append((newname, objects[newname]))
        return matches

    def resolve_xref(self, env, fromdocname, builder, type, target, node,
                     contnode):
        funcname = node.get('q:function')
        searchmode = 1 if node.hasattr('refspecific') else 0
        matches = self.find_obj(env, funcname, target, type, searchmode)
        if not matches:
            return None
        elif len(matches) > 1:
            env.warn_node(
                'more than one target found for cross-reference '
                '%r: %s' % (target, ', '.join(match[0] for match in matches)),
                node)
        name, obj = matches[0]

        if obj[1] == 'function':
            docname, synopsis, platform, deprecated = self.data['functions'][name]
            assert docname == obj[0]
            title = name
            if synopsis:
                title += ': ' + synopsis
            if deprecated:
                title += ' (deprecated)'
            if platform:
                title += ' (' + platform + ')'
            return make_refnode(builder, fromdocname, docname,
                                'function-' + name, contnode, title)
        else:
            return make_refnode(builder, fromdocname, obj[0], name,
                                contnode, name)

    def get_objects(self):
        for funcname, info in self.data['functions'].iteritems():
            yield (funcname, funcname, 'function', info[0], 'function-' + funcname, 0)
        for refname, (docname, type) in self.data['objects'].iteritems():
            yield (refname, refname, type, docname, refname, 1)



def setup(app):
    app.add_config_value('qdomain_funcindex_common_prefix', [], 'html')
    app.add_domain(QDomain)
