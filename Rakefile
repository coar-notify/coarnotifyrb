require "rake"
require "rake/clean"

CLEAN.include("build/*")

desc "Build the gem"
task :build do
  sh "gem build coarnotifyrb.gemspec"
  mv Dir.glob("*.gem").first, "build/"
end
