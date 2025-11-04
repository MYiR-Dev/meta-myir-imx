FILESEXTRAPATHS:prepend := "${THISDIR}/files:"


SRC_URI += " \
    file://mx93a1-ahab-container.img \
"


do_patch:append() {

    import os
    import shutil
    
    workdir = d.getVar('WORKDIR')
    s = d.getVar('S')
    src_file = os.path.join(workdir, 'mx93a1-ahab-container.img')
    dst_file = os.path.join(s, 'mx93a1-ahab-container.img')
    
    if os.path.isfile(src_file):
        bb.note("Replacing mx93a1-ahab-container.img with custom version")
        shutil.copy2(src_file, dst_file)
}