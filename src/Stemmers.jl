module Stemmers

export stemmer_types, Stemmer, stem

const _libsb = "libstemmer"

##
# character encodings supported by libstemmer
const UTF_8         = "UTF_8"
const ISO_8859_1    = "ISO_8859_1"
const CP850         = "CP850"
const KOI8_R        = "KOI8_R"

##
# lists the stemmer algorithms loaded
function stemmer_types()
    cptr = ccall((:sb_stemmer_list, _libsb), Ptr{Ptr{Uint8}}, ())
    (C_NULL == cptr) && error("error getting stemmer types")

    stypes = String[]
    i = 1
    while true
        name_ptr = unsafe_load(cptr, i)
        (C_NULL == name_ptr) && break
        push!(stypes, bytestring(name_ptr))
        i += 1
    end
    stypes
end

type Stemmer
    cptr::Ptr{Void}
    alg::String
    enc::String

    function Stemmer(stemmer_type::String, charenc::String=UTF_8)
        cptr = ccall((:sb_stemmer_new, _libsb), Ptr{Void}, (Ptr{Uint8}, Ptr{Uint8}), bytestring(stemmer_type), bytestring(charenc))
        (C_NULL == cptr) && error("error creating stemmer of type $(stemmer_type) for $(charenc) encoding")
        stm = new(cptr, stemmer_type, charenc)
        finalizer(stm, release)
        stm
    end
end

function release(stm::Stemmer)
    (C_NULL == stm.cptr) && return
    ccall((:sb_stemmer_delete, _libsb), Void, (Ptr{Void},), stm.cptr)
    stm.cptr = C_NULL
    nothing
end

function stem(stemmer::Stemmer, word::String)
    bstr = bytestring(word)
    sres = ccall((:sb_stemmer_stem, _libsb), Ptr{Uint8}, (Ptr{Uint8}, Ptr{Uint8}, Cint), stemmer.cptr, bstr, length(bstr))
    (C_NULL == sres) && error("error in stemming")
    slen = ccall((:sb_stemmer_length, _libsb), Cint, (Ptr{Void},), stemmer.cptr)
    bytes = pointer_to_array(sres, int(slen), false)
    bytestring(bytes)
end

function stem(stemmer::Stemmer, words::Array{String})
    l = length(words)
    ret = Array(String, l)
    for idx in 1:l
        ret[idx] = stem(stemmer, words[idx])
    end
    ret
end

end
