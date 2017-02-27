import 'vendor/xterm/encoding-indexes.js';
import 'vendor/xterm/encoding.js';
import Terminal from 'vendor/xterm/xterm.js';
import 'vendor/xterm/fit.js';
import './terminal.js';

window.Terminal = Terminal;

$(() => new gl.Terminal({ selector: '#terminal' }));
