require 'net/ssh'
require 'net/scp'
require 'net/sftp'

#
# FIXME /tmp en dur !!!
#

module EbSSH

   def EbSSH::open_session(slave,pass)
      begin
         session = nil
         if slave.auth_method == "key"
            session = Net::SSH.start(slave.ip,cli.user,
               :keys => slave.private_key,
               :passphrase => "#{pass}"
            )
         elsif slave.auth_method == "password"
            session = Net::SSH.start(slave.ip,cli.user, :password => pass)
         else
            RmtPrint::stdmessage("Error : [#{slave.auth_method}] is not a valid authentification method")
            RmtPrint::sepline
            return nil
         end
         return session
      rescue => err
         RmtPrint::stdmessage("Error opening session on #{slave.name}")
         return nil
      end
   end


   def EbSSH::copy_id(slave,password="")
      ret = EbSSH::copy_file(slave,client.public_key,"/tmp",password)
      final = 0
      output = ""
      if ret == 0
         rfile = "#{"/tmp"}/#{File.basename(slave.public_key)}"

         cmd = "cat #{rfile} >> .ssh/authorized_keys "
         ret = EbSSH::run(slave,cmd,password)
         output += ret[0]
         final += ret[1]

         cmd = "chmod -R 700 .ssh"
         ret = EbSSH::run(slave,cmd,password)
         output += ret[0]
         final += ret[1]

         cmd = "rm #{rfile}"
         ret = EbSSH::run(slave,cmd,password)
         output += ret[0]
         final += ret[1]
         if final != 0
            RmtPrint::stdmessage("Error : Copy SSH id Failed !! [#{output}")
            #return 2
         end
         #puts ret[1]
      else
         cli.clean_keys
         RmtPrint::stdmessage("Error : copy ssh id Failed")
         RmtPrint::sepline
         return 2
      end
   end

   def EbSSH::random_pass(len)
      chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a 
      chars.push(" ")
      newpass = ""
      1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
      return newpass
   end

   def EbSSH::key_gen(dst,name)
      t = Time.now
      public_file = "#{dst}/key-#{name}-#{t.strftime("%d%m%y-%H%M%S")}.pub"
      private_file = "#{dst}/key-#{name}-#{t.strftime("%d%m%y-%H%M%S")}"
      pass = ""
      3.times do
         pass += EbSSH::random_pass(rand(6) + rand(4))
      end


      `ssh-keygen -f #{private_file} -t rsa -b 4096 -C "rEmote Key for #{name}"  -P "#{pass}"`

      FileUtils.chmod(0700,public_file)
      FileUtils.chmod(0700,private_file)

      return { "private" => private_file,
         "public"  => public_file,
         "pass"    => pass
      }
   end


   def EbSSH::mkdir_p(session,dest)
      to_mkdir = dest.split("/")
      directory = ""
      to_mkdir.each do |dir|
         if dir == ""
            directory += "/"
            next
         else
            directory += "#{dir}/"
            begin
               if session.stat!(directory).directory?
                  next
               else
                  session.mkdir!(directory, :permissions => 0750)
               end
            rescue
               session.mkdir!(directory, :permissions => 0750)
            end
         end
      end
   end


   def EbSSH::run_script(session, file)
      script = []
      output = ""
      exit_code = 0
   
      if file.class == Array
        script = file
      elsif file.class == String
        if File.exist?(file)
          fd = File.open(file)
          fd.each_line { |li| script << li }
          fd.close
          if ! script[-1] =~ /exit/
            return [ "ERROR : invalid script #{file}" , 2 ]
          end
        elsif file.class == Array
          script = file
        else
          return [ "ERROR" , 127 ]
        end
      end
      session.open_channel do |channel|
         channel.send_channel_request "shell" do |ch,success|
            abort "could not run_script" unless success
         end

         # # 	 channel.request_pty do |ch,success| # 	    abort "could not run script pty failure" unless success
         #         end
   
         channel.on_data do |ch, data|
            output += data
         end
   
         channel.on_extended_data do |ch, type, data|
            output += data
         end
   
         channel.on_request("exit-status") do |ch, data|
            exit_code = data.read_long
         end
   
         channel.on_close do |ch|
           return [ output , exit_code ]
         end
   
         script.each do |cmd|
            # This : 
            if cmd =~ /^exit/ 
               channel.send_data("#{cmd}\n")
            end
            # Fix double exit bug on script run
            channel.send_data("#{cmd}\n")
         end
      end
      session.loop
   end

   #
   # NAME : run_cmd AIM : run ssh command RETURN : Array with [ output, exit_code ]
   #

   def EbSSH::run_cmd(session,cmd,env=nil)
      exit_code = 0
      begin 
         channel = session.open_channel do |ch|
            output = "" 
            if env
               env.each_pair do |k,d|
                  ch.env(k,d)
               end
            end
            ch.exec(cmd) do |chann, success|
               raise "could not execute command" unless success
    
               # "on_data" is called when the process writes something to stdout
               chann.on_data do |c, data|
                  output += data
                  # #$stdout.print("#{data}")
               end
    
               # "on_extended_data" is called when the process writes something to stderr
               chann.on_extended_data do |c, type, data|
                  output += data
                  # #$stderr.print("#{data}")
               end
    
               chann.on_request("exit-status") do |c, data|
                  exit_code = data.read_long
                  # #if exit_code > 0
                  #   RmtPrint::stdmessage "ERROR: [#{cmd}] exit code [#{exit_code}]"
                  # #else
                  #   RmtPrint::stdmessage "|--> Command [#{cmd}] Success"
                  # #end
               end
                
               chann.on_close do
                  res = [output,exit_code]
                  return res 
               end
            end
         end
         channel.wait
      rescue
         RmtPrint::stdmessage "SSH Channel Failed : #{$!}"
         return 2
      end
   end

   def EbSSH::run(remotecl,cmd,password="")
     begin 
       session = nil
       if remotecl.class == Net::SSH::Connection::Session
         session = remotecl 
       else
         session = EbSSH::open_session(remotecl,password)
       end
       if session == nil
         RmtPrint::stdmessage("Error : Openning SSH Session")
         return ["EbSSH Session Error",127]
       elsif cmd.class == Array
         return run_script(session,cmd)
=begin
         result = {}
         cmd.each do |command| 
           result[command] = run_cmd(session,command)
         end
         return result	
=end
       elsif cmd.class == String and File.exist?(cmd)
         return run_script(session,cmd)
       else
         return run_cmd(session,cmd)
       end
     rescue
       RmtPrint::stdmessage "Error : Command run over SSH failed [#{$!}]"
       return ["EbSSH::run Error", 127]
     end
   end

   def EbSSH::copy_file(remotecl,src,dest,password="")

      if File.exist?(src)
         local_change = nil
         to_upload = false
         begin
            session = EbSSH::open_session(remotecl,password)
            remote_file_name = dest + "/" + File.basename(src)
            session.sftp.connect do |sp|
               EbSSH::mkdir_p(sp,dest)

               begin
                  mtime = File.stat(src).mtime > Time.at(sp.stat!(remote_file_name).mtime)
                  size  = File.stat(src).size != sp.stat!(remote_file_name).size
                  if mtime and size 
                     local_change = true
                  end
               rescue Net::SFTP::StatusException
                  RmtPrint::stdmessage("Remote file is missing :")
                  RmtPrint::stdmessage("   uploading ...")
                  to_upload = true
                  STDOUT.flush
               end 
               begin
                  if local_change or to_upload  
                     sp.upload!(src, remote_file_name) do |event, uploader, *args|
                        case event
                        when :open then
                           # args[0] : file metadata
                           RmtPrint::stdmessage "."
                           STDOUT.flush
                        when :put then
                           RmtPrint::stdmessage "."
                           STDOUT.flush
                           # args[0] : file metadata args[1] : byte offset in remote file args[2] : data being written (as string) #when :close then RmtPrint::stdmessage
                           # "\nClosed" args[0] : file metadata #when :mkdir then args[0] : remote path name
                        when :finish then
                           RmtPrint::stdmessage "Copy of #{src} to #{remote_file_name} -> [OK]"
                        end
                     end
                  else
                     RmtPrint::stdmessage "Info : File #{remote_file_name} exist and have not changed"
                  end
               rescue
                  RmtPrint::stdmessage "\nUpload of [#{src}] to #{remotecl.name}:#{dest} Failed #{$!}"
                  return false
               end
            end
         rescue
            RmtPrint::stdmessage "Error : File copy failed [#{$!}]"
            return 127
         end
      else
         RmtPrint::stdmessage "Error : File [#{src}] is missing for copy"
         return 127
      end
      return 0
   end

end
