require_relative './test_helper'

# NOTE: Adapter tests must be run with ENV['NO_BUNDLER'] == '1'. This disables
# bundler's setup so that we can require un-bundled gems.
# I don't want to have to list all the adapter gems in the bundle.


# Allow requiring different versions of gems
# I don't want to require having all the adapter gems in the bundle to run a test
def adapter_require(*gems)
  required = nil
  begin
    gems.each do |gem|
      require_name = nil
      if gem.is_a?(Array)
        gem_name = gem[0]
        version = gem[1]
        require_name = gem[2]
      elsif gem.is_a?(Hash)
        gem_name = gem[:name]
        version = gem[:version]
        require_name = gem[:require]
      else
        gem_name = gem
      end
      version ||= ENV["TEST_#{gem_name.upcase}_VERSION"]
      version ||= '>= 0'
      gem gem_name, version
      require(require_name || gem_name)
      required = true    
    end
  rescue
    required = false
  end

  yield if required
end
