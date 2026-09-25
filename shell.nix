{ pkgs ? import <nixpkgs> {} }:

let
  # ============================================
  # 根据 build.sh 的 required_tools / optional_tools
  # / perl_modules / py_modules 整理的依赖
  # ============================================

  # 必需的系统工具（对应 required_tools 数组）
  requiredTools = with pkgs; [
    gnumake          # make
    gcc              # gcc
    gcc              # g++（gcc 包里包含 g++）
    dtc              # dtc (device-tree-compiler)
    python3          # python3
    perl             # perl
    coreutils        # truncate, stat, rm, mkdir, cp, mv
    findutils        # find
    zip              # zip
    gnutar           # tar
  ];

  # 可选工具（对应 optional_tools，用于网页文件压缩）
  # 注意：这些是 npm 全局包，由 build.sh 的 install_deps 通过 npm 安装，
  # 不是 Nix 包。这里不放进 buildInputs，避免冲突。
  # 如需在 FHS 环境里使用，可以在 shellHook 里手动 npm install -g。
  # optionalTools = [ html-minifier-terser cleancss terser ];

  # Perl 模块 IO::Compress::Gzip（对应 perl_modules 数组）
  # Nix 中由 perl 包自带，若缺失可补 perlPackages.IOCompress
  perlModules = with pkgs.perlPackages; [
    IOCompress
  ];

  # Python3 模块 os / sys / struct 都是标准库，python3 自带，无需额外包

  # 编译过程中可能需要的额外库（QSDK/U-Boot 常见依赖）
  extraLibs = with pkgs; [
    ncurses
    zlib
    openssl
    libelf
    glibc
    glibc.static
    flex
    bison
    bc
    cpio
    file
    gawk
    gettext
    patch
    wget
    curl
    unzip
    rsync
    pkg-config
    cmake
    ninja
    ccache
    # 镜像/文件系统工具
    cdrkit
    squashfsTools
    genext2fs
    mtools
    dosfstools
    libuuid
  ];

  buildDeps = requiredTools ++ perlModules ++ extraLibs;

  fhs = pkgs.buildFHSEnv {
    name = "uboot-qsdk-env";
    targetPkgs = pkgs: buildDeps;

    # 关键：禁用 Nix 编译器加固，SDK 自带的工具链/源码通常不兼容
    profile = ''
      export hardeningDisable=all

      # 让脚本能找到工具链目录（与 setup_build_env 保持一致）
      export STAGING_DIR="$PWD/staging_dir"
      export PATH="$PWD/staging_dir/toolchain-arm_cortex-a7_gcc-5.2.0_musl-1.1.16_eabi/bin:$PATH"
    '';

    # 可选：进入环境后安装 Node.js 压缩工具
    # shellHook = ''
    #   if command -v npm >/dev/null 2>&1; then
    #     npm install -g html-minifier-terser clean-css-cli terser
    #   fi
    # '';
  };
in
fhs.env
