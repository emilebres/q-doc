# -*- coding: utf-8 -*-
"""
    sphinx.domains.q
    ~~~~~~~~~~~~~~~~~~

    The q domain.

    :copyright: Copyright 2007-2011 by the Sphinx team, see AUTHORS.
    :license: BSD, see LICENSE for details.
"""

import re

from sphinx import addnodes
from sphinx.domains import Domain, ObjType
from sphinx.locale import l_, _
from sphinx.directives import ObjectDescription
from sphinx.roles import XRefRole
from sphinx.util.nodes import make_refnode


dir_sig_re = re.compile(r'\.\. (.+?)::(.*)$')


class QObject(ObjectDescription):
    """
    Description of generic q object.
    """

    def add_target_and_index(self, name, sig, signode):
        targetname = self.objtype + '-' + name
        if targetname not in self.state.document.ids:
            signode['names'].append(targetname)
            signode['ids'].append(targetname)
            signode['first'] = (not self.names)
            self.state.document.note_explicit_target(signode)

            objects = self.env.domaindata['rst']['objects']
            key = (self.objtype, name)
            if key in objects:
                self.env.warn(self.env.docname,
                              'duplicate description of %s %s, ' %
                              (self.objtype, name) +
                              'other instance in ' +
                              self.env.doc2path(objects[key]),
                              self.lineno)
            objects[key] = self.env.docname
        indextext = self.get_index_text(self.objtype, name)
        if indextext:
            self.indexnode['entries'].append(('single', indextext,
                                              targetname, ''))

    def get_index_text(self, objectname, name):
        if self.objtype == 'directive':
            return _('%s (directive)') % name
        elif self.objtype == 'role':
            return _('%s (role)') % name
        return ''

class QFunction(QObject):
    """
    Description of a q function.
    """
    def handle_signature(self, sig, signode):
        name, args = parse_function(sig)
        return name + '[' + ';'.join(args) + ']'

    def parse_function(f):
        f = f.strip()
        m = re.match(r'(.*):\s?{\s?\[(.*)\]', f)
        if not m:
            m = re.match(r'(.*):\s?{', f)
            return (m.groups(0), '')
        return m.groups()

class QVariable(QObject):
    """
    Description of a q variable.
    """
    def handle_signature(self, sig, signode):
        signode += addnodes.desc_name(':%s:' % sig, ':%s:' % sig)
        return sig


class QDomain(Domain):
    """q domain."""
    name = 'q'
    label = 'q language for kdb+'

    object_types = {
        'namespace': ObjType(l_('namespace'), 'namespace', 'ref'),
        'function': ObjType(l_('function'), 'function', 'ref'),
        'variable': ObjType(l_('variable'), 'variable', 'ref')
    }
    directives = {
        'namespace': QNamespace,
        'function': QFunction,
        'variable': QVariable
    }
    roles = {
        'ns': XRefRole(),
        'func':  XRefRole(),
        'var': XRefRole()
    }
    initial_data = {
        'objects': {},  # fullname -> docname, objtype
    }

    def clear_doc(self, docname):
        for fullname, (fn, _, _) in self.data['objects'].items():
            if fn == docname:
                del self.data['objects'][fullname]

    def resolve_xref(self, env, fromdocname, builder, typ, target, node,
                     contnode):
        objects = self.data['objects']
        objtypes = self.objtypes_for_role(typ)
        for objtype in objtypes:
            if (objtype, target) in objects:
                return make_refnode(builder, fromdocname,
                                    objects[objtype, target],
                                    objtype + '-' + target,
                                    contnode, target + ' ' + objtype)

    def get_objects(self):
        for (typ, name), docname in self.data['objects'].iteritems():
            yield name, name, typ, docname, typ + '-' + name, 1