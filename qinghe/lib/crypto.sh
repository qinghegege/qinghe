#!/system/bin/sh
#===============================================================================
# 清荷 - 加密模块 (openssl aes-256-cbc)
#===============================================================================

encrypt_file() {
    _input="$1"
    _output="$2"
    _pass="$3"

    if [ "$HAS_OPENSSL" != true ]; then
        log_err "openssl 不可用, 无法加密"
        return 1
    fi

    openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt \
        -in "$_input" -out "$_output" \
        -pass pass:"$_pass" 2>/dev/null

    return $?
}

decrypt_file() {
    _input="$1"
    _output="$2"
    _pass="$3"

    if [ "$HAS_OPENSSL" != true ]; then
        log_err "openssl 不可用, 无法解密"
        return 1
    fi

    openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -d \
        -in "$_input" -out "$_output" \
        -pass pass:"$_pass" 2>/dev/null

    return $?
}

tar_encrypt() {
    _dir="$1"
    _output="$2"
    _pass="$3"

    if [ "$HAS_OPENSSL" != true ]; then
        log_err "openssl 不可用, 无法加密"
        return 1
    fi

    _tmp="/tmp/qinghe_tar_enc_$$.tar.gz"
    _parent="$(dirname "$_dir")"
    _dir_name="$(basename "$_dir")"

    cd "$_parent" || return 1
    tar czf "$_tmp" "$_dir_name" 2>/dev/null || { rm -f "$_tmp"; return 1; }

    encrypt_file "$_tmp" "$_output" "$_pass"
    _rc=$?
    rm -f "$_tmp"
    return $_rc
}

tar_decrypt() {
    _input="$1"
    _output_dir="$2"
    _pass="$3"

    if [ "$HAS_OPENSSL" != true ]; then
        log_err "openssl 不可用, 无法解密"
        return 1
    fi

    _tmp="/tmp/qinghe_tar_dec_$$.tar.gz"
    decrypt_file "$_input" "$_tmp" "$_pass" || { rm -f "$_tmp" 2>/dev/null; return 1; }

    mkdir -p "$_output_dir"
    tar xzf "$_tmp" -C "$_output_dir" 2>/dev/null
    _rc=$?
    rm -f "$_tmp"
    return $_rc
}
