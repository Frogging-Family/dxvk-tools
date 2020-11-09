# DXVK & vkd3d-proton script to build/patch/install/update, Lutris and Proton-tkg compatible.

### Requirements:
- [wine 3.10](https://www.winehq.org/) or newer
- [Meson](http://mesonbuild.com/) build system (at least version 0.43)
- [MinGW64](http://mingw-w64.org/) 8.0 compiler and headers (I'm providing a distro-agnostic script to build it here: https://github.com/Frogging-Family/dxvk-tools )
- [glslang](https://github.com/KhronosGroup/glslang) compile
- Optional : Installing ccache will greatly improve subsequent compilation times

### Building DXVK DLLs

Inside the dxvk-tools directory, run:
```
./updxvk build
```

### Building vkd3d-proton DLLs

Inside the dxvk-tools directory, run:
```
./upvkd3d-proton build
```

### Exporting DXVK DLLs for Proton-tkg

Still inside the dxvk-tools directory, after you ran the command above, run:
```
./updxvk proton-tkg
```
*DXVK files will be copied in a folder next to proton-tkg script, ready for building.*


You'll find more details on the various functions (such as installation-related ones) of these scripts right inside them.

# DXVK : https://github.com/doitsujin/dxvk
# vkd3d-proton : https://github.com/HansKristian-Work/vkd3d-proton
