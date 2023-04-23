require_relative "opt_builder"

module MojoMagick
  class Commands
    def self.raw_command(*args)
      execute!(*args)
    end

    class << self
      private

      def execute(command, *args)
        execute = "#{command} #{args}"
        out, outerr, status = Open3.capture3(command, *args.map(&:to_s))
        CommandStatus.new execute, out, outerr, status
      rescue StandardError => e
        raise MojoError, "#{e.class}: #{e.message}"
      end

      def execute!(command, *args)
        status = execute(command, *args)
        unless status.success?
          err_msg = "MojoMagick command failed: #{command}."
          raise(MojoFailed, "#{err_msg} (Exit status: #{status.exit_code})\n  " \
                            "Command: #{status.command}\n  " \
                            "Error: #{status.error}")
        end
        status.return_value
      end
    end
  end
end
