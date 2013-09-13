using BinDeps

@BinDeps.setup

deps = [
    libstemmer = library_dependency("libstemmer", aliases=["libstemmer", "libstemmer.so", "libstemmer.dylib", "libstemmer.dll"])
]

provides(Sources, {URI("http://snowball.tartarus.org/dist/snowball_code.tgz") => libstemmer})

prefix=joinpath(BinDeps.depsdir(libstemmer),"usr")
srcdir = joinpath(BinDeps.depsdir(libstemmer),"src","snowball_code")
patchpath = joinpath(BinDeps.depsdir(libstemmer),"patches","libstemmer-so.patch")
binpath = joinpath(prefix,"lib","libstemmer.so")

provides(BuildProcess,
    (@build_steps begin
        GetSources(libstemmer)
        ChangeDirectory(srcdir)
        FileRule(binpath, @build_steps begin
            `patch < $patchpath`
            `gnumake`
            `cp libstemmer.so.0d.0.0 $binpath`
        end)
    end), libstemmer, os = :Unix)
            
