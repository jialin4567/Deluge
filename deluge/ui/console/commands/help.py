# help.py
#
# Copyright (C) 2008-2009 Ido Abramovich <ido.deluge@gmail.com>
# Copyright (C) 2009 Andrew Resch <andrewresch@gmail.com>
#
# Deluge is free software.
#
# You may redistribute it and/or modify it under the terms of the
# GNU General Public License, as published by the Free Software
# Foundation; either version 3 of the License, or (at your option)
# any later version.
#
# deluge is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with deluge.    If not, write to:
# 	The Free Software Foundation, Inc.,
# 	51 Franklin Street, Fifth Floor
# 	Boston, MA    02110-1301, USA.
#

from twisted.internet import defer

from deluge.ui.console.main import BaseCommand
import deluge.ui.console.colors as colors
import deluge.component as component

class Command(BaseCommand):
    """displays help on other commands"""

    usage =  "Usage: help [command]"

    def handle(self, *args, **options):
        self.console = component.get("ConsoleUI")
        self._commands = self.console._commands
        deferred = defer.succeed(True)
        if args:
            if len(args) > 1:
                self.console.write(usage)
                return deferred
            try:
                cmd = self._commands[args[0]]
            except KeyError:
                self.console.write("{!error!}Unknown command %r" % args[0])
                return deferred
            try:
                parser = cmd.create_parser()
                self.console.write(parser.format_help())
            except AttributeError, e:
                self.console.write(cmd.__doc__ or 'No help for this command')
        else:
            max_length = max( len(k) for k in self._commands)
            for cmd in sorted(self._commands):
                self.console.write("{!info!}" + cmd + "{!input!} - " + self._commands[cmd].__doc__ or '')
            self.console.write(" ")
            self.console.write('For help on a specific command, use "<command> --help"')

        return deferred

    def complete(self, line):
        return [x for x in component.get("ConsoleUI")._commands if x.startswith(line)]
