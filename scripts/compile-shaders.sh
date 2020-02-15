#!/bin/env bash
bgfxdir=$HOME/packages/bgfx
shader_dir=src/shaders
shader="flat"
shopt -s globstar

profiles=("spirv" "130")

# $bgfxdir/.build/linux64_gcc/bin/shadercRelease \
#     -f src/shaders/f_flat.sc \
#     -o f_flat.sc.glsl \
#     -i $bgfxdir/src
#     --type fragment \ 
#     --platform linux \

# exit
compile() {
    f=$1
    profile=$2
    type=$3
    filename=$(basename "$f")
    name=$(echo "$filename" | cut -f1 -d'.')
    dname=$profile
    case $profile in
        "130")
            echo "dname"
            dname="glsl"
            ;;
    esac
    dir=$(dirname "$f")/$dname
    out=$dir/$name.bin
    mkdir -p $dir
    echo "$f -> $out"
    $bgfxdir/.build/linux64_gcc/bin/shadercRelease \
        -f $f \
        -o $out \
        -p $profile \
        --platform linux \
        --type $type \
        --verbose \
        -i $bgfxdir/src
}

cd $shader_dir
echo "Compiling fargment shaders"
for f in **/f_*.sc; do
    for profile in ${profiles[@]}; do
        compile $f $profile "fragment"
    done
done
echo "Compiling vertex shaders"
for f in **/v_*.sc; do
    for profile in ${profiles[@]}; do
        compile $f $profile "vertex"
    done
done
# echo "Compiling vertex shaders"
# for f in **/v_*.sc; do
#     out=$(echo "$f" | cut -f1 -d'.')
#     echo "$f -> $out.bin"
#     $bgfxdir/.build/linux64_gcc/bin/shadercRelease \
#         -f $f \
#         -o $out.bin \
#         -p 120 \
#         --platform linux \
#         --type vertex \
#         --verbose \
#         -i $bgfxdir/src
# done
# $bgfxdir/.build/linux64_gcc/bin/shadercRelease \
#     -f f_flat.sc \
#     -o f_flat.bin \
#     --platform linux \
#     --type fragment \
#     --verbose \
#     -i $bgfxdir/src