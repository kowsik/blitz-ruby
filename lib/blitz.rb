require 'rubygems'
require 'couchrest'
require 'hexy'
require 'pp'

class Blitz
    require 'blitz/helper'
    Version = "0.1.3".freeze
        
    extend Blitz::Helper
    
    def self.run cmd, argv
        kname, mname = cmd.split(':', 2)
        klass = Blitz::Command.const_get kname.capitalize rescue nil
        mname ||= 'default'
        mname = "cmd_#{mname}".to_sym
        if klass and klass < Blitz::Command and klass.method_defined? mname
            command = klass.new
            begin
                command.send mname, argv
            rescue Test::Unit::AssertionFailedError, ArgumentError => e
                error e.message.chomp('.')
            end
        else
            error "Unknown command #{cmd}"
        end        
    end    
end

require 'blitz/client'
require 'blitz/curl/error'
require 'blitz/curl/sprint'
require 'blitz/curl/rush'
require 'blitz/command'
