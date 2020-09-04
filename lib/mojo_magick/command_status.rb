module MojoMagick
  CommandStatus = Struct.new(:command, :return_value, :error, :system_status) do
    def success?
      system_status.success?
    end

    def exit_code
      system_status.exitstatus || 'unknown'
    end
  end
end
