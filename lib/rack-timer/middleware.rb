
require 'rack'

module RackTimer

  module ModuleMethods
    def log(message)
      (@_output || $stderr).puts(message)
    end

    def output=(io)
      @_output = io
    end
  end
  extend ModuleMethods


  class Middleware

    def initialize(app)
      @app = app
      self.extend(Borg)
      _log "started borg collective: #{self.class.name}"
    end

    def call(env)
      @app.call(env)
    end

    module Borg
      def self.extended(object)
        object.singleton_class.class_eval do
          alias_method :call_without_timing, :call
          alias_method :call, :call_with_timing
          public :call
        end

        object.instance_eval do
          _log "assimilating: #{object.class.name}"
          recursive_borg
        end
      end

      def borged?
        true
      end

      private

      def recursive_borg
        return if @app.nil?
        return if @app.respond_to?(:borged?)
        return unless @app.respond_to?(:call)
        @app.extend(Borg)
      end

      def call_with_timing(env)
        time_before = _current_ticks
        result = call_without_timing(env)
        time_delta = _current_ticks - time_before

        if time_inner = env['rack-timer.time']
          time_inner = time_inner.to_i
          time_self = time_delta - time_inner 
        else
          time_self = time_delta
        end
        _log "#{self.class.name} took #{time_self} us"

        if (request_start = env['HTTP_X_REQUEST_START']) && kind_of?(RackTimer::Middleware)
          time_queue_start = request_start.gsub('t=', '').to_i
          time_in_queue = time_before - time_queue_start
          _log "queued for #{time_in_queue} us"
        end

        env['rack-timer.time'] = time_delta
        return result
      end

      def _log(message)
        RackTimer.log "[rack-timer] #{message}"
      end

      def _current_ticks
        (Time.now.to_f * 1e6).to_i
      end
    end
  end
end
