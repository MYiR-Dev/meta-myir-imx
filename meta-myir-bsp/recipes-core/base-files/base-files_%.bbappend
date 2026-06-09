# MYiR hostname per-machine mapping
# base-files is allarch so MACHINE overrides don't apply; use Python mapping instead
python () {
    hostname_map = {
        'myd-jmx95-15x15-lpddr5': 'myd-jmx95-15x15',
    }
    machine = d.getVar('MACHINE')
    if machine in hostname_map:
        d.setVar('hostname', hostname_map[machine])
}
