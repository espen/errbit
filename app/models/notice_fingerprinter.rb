# frozen_string_literal: true

class NoticeFingerprinter
  include Mongoid::Document
  include Mongoid::Timestamps

  field :error_class, default: true, type: Boolean
  field :message, default: true, type: Boolean
  field :backtrace_lines, default: -1, type: Integer
  field :component, default: true, type: Boolean
  field :action, default: true, type: Boolean
  field :environment_name, default: true, type: Boolean
  field :source, type: String

  embedded_in :app
  embedded_in :site_config

  def generate(api_key, notice, backtrace)
    material = [api_key]
    material << notice.error_class if error_class
    material << notice.filtered_message if message
    material << notice.environment_name if environment_name

    # Sometimes backtrace is nil
    if backtrace&.lines.present?
      if backtrace_lines < 0
        material << backtrace.lines
      else
        material << backtrace.lines.slice(0, backtrace_lines)
      end
    else
      # Without a backtrace the request context is the only way to tell
      # notices apart. When a backtrace is present it already identifies the
      # raise site, and mixing in component/action would split errors raised
      # outside controller code (e.g. middleware) into one problem per action.
      material << notice.component if component
      material << notice.action if action
    end

    Digest::MD5.hexdigest(material.join)
  end
end
