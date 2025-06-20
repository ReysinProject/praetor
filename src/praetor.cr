module Praetor

  VERSION = "0.1.0"
  
  # Build information
  BUILD_DATE = {{ `date -u +%Y-%m-%d`.stringify.chomp }}
  BUILD_COMMIT = {{ `git rev-parse --short HEAD 2>/dev/null || echo "unknown"`.stringify.chomp }}
  
  def self.version_info : String
    "Validation v#{VERSION} (built #{BUILD_DATE}, commit #{BUILD_COMMIT})"
  end
end