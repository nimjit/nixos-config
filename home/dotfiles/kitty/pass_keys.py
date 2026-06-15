import subprocess


def main(args):
    pass


def handle_result(args, answer, target_window_id, boss):
    direction = args[1]  # 'left', 'right', 'top', 'bottom'
    key = args[2]        # 'ctrl+h', 'ctrl+j', 'ctrl+k', 'ctrl+l'

    window = boss.active_window
    if window is None:
        return

    def is_nvim(w):
        try:
            pid = w.child.pid
            with open(f'/proc/{pid}/comm') as f:
                if f.read().strip() == 'nvim':
                    return True
            # Check foreground process group for nvim spawned from shell
            with open(f'/proc/{pid}/stat') as f:
                fg_pgid = f.read().split()[7]
            result = subprocess.run(
                ['pgrep', '-g', fg_pgid, 'nvim'],
                capture_output=True
            )
            return result.returncode == 0
        except Exception:
            return False

    KEY_BYTES = {
        'ctrl+h': b'\x08',
        'ctrl+j': b'\n',
        'ctrl+k': b'\x0b',
        'ctrl+l': b'\x0c',
    }

    if is_nvim(window):
        window.write_to_child(KEY_BYTES.get(key, b''))
    else:
        boss.active_tab.neighboring_window(direction)
