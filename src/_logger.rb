#!/usr/bin/env ruby
<<'EOF_LICENSE'
Copyright 2013 Ben Gimpert (ben@somethingmodern.com)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
EOF_LICENSE

class Numeric

  def frac
    self.modulo(1)
  end

  def to_comma_s
    s = (self.frac.zero? ? self.to_s : self.to_float_s)
    s.reverse.scan(/(?:\d*\.)?\d{1,3}-?/).join(',').reverse
  end

end

class Time

  def to_timestamp
    ms_s = sprintf("%03d", (self.to_f.frac * 1_000).to_i)
    self.strftime("%Y-%m-%d %H:%M:%S.#{ms_s} %z")
  end

end

class Logger

  IS_PROFILING_MEMORY = false

  def self.csv?;      true
  end
  def self.db?;       true
  end
  def self.verbose?;  false
  end
  def self.debug?;    true
  end
  def self.info?;     true
  end
  def self.warn?;     true
  end
  def self.error?;    true
  end

  def self.to_console(level, msg)
    if msg.is_a?(Exception)
      to_console(level, "Exception: #{msg.message}")
      msg.backtrace.each { |backtrace_line| to_console(level, "  #{backtrace_line}") } unless msg.backtrace.nil?
      return
    end

    prefixed_msg = "[#{Time.now.to_timestamp}] -- PID(#$$) -- #{level}"
    if IS_PROFILING_MEMORY
      mem_usage = `ps -o rss= -p #{$$}`.to_f / 1_024
      prefixed_msg += " -- #{mem_usage.to_float_s(2)}mb"
    end
    prefixed_msg += " -- #{msg}"
    $stderr.puts prefixed_msg
  end

  def self.csv(*cols)
    $stdout.puts CSV.generate_line(["____CSV____"] + cols)
  end

  def self.db(msg)
    to_console("   DB", msg)
  end

  def self.verbose(msg)
    to_console(" VERB", msg)
  end

  def self.debug(msg)
    to_console("DEBUG", msg)
  end

  def self.info(msg)
    to_console(" INFO", msg)
  end

  def self.warn(msg)
    to_console(" WARN", msg)
  end

  def self.error(msg)
    to_console("ERROR", msg)
  end

end


