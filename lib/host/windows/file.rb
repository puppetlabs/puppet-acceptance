module Windows::File
  include CommandFactory

  def tmpfile(name)
    execute("cygpath -m $(mktemp -t #{name}.XXXXXX)")
  end

  def tmpdir(name)
    execute("cygpath -m $(mktemp -td #{name}.XXXXXX)")
  end

  def rm_rf(path)
    execute("rm -rf #{path}")
  end

  def path_split(paths)
    paths.split(';')
  end
end
