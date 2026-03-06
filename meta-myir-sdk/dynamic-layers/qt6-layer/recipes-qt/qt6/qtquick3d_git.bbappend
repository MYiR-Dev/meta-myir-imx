PACKAGECONFIG:class-target:append = " openxr"

PACKAGECONFIG[openxr] = "-DFEATURE_quick3dxr_openxr=ON,-DFEATURE_quick3dxr_openxr=OFF"
