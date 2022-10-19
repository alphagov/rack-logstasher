require "tempfile"

module LogfileHelper
  TMP_LOGFILE = Tempfile.new("rack-logstasher-tmp-log")

  def reset_tmp_log
    TMP_LOGFILE.rewind
    TMP_LOGFILE.truncate(0)
  end

  def tmp_logfile_path
    TMP_LOGFILE.path
  end

  def last_log_line
    TMP_LOGFILE.readlines.last
  end
end

RSpec.configuration.include(LogfileHelper)
RSpec.configuration.before do
  reset_tmp_log
end
