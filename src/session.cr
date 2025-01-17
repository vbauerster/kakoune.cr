require "./commands"
require "./arguments"
require "./client"
require "./buffer"
require "./process"

class Kakoune::Session
  include Commands

  property name : String

  def initialize(@name)
  end

  def send(command)
    input = IO::Memory.new(command)
    Process.run("kak", { "-p", name }, input: input)
  end

  def send(command, arguments)
    command = Arguments.escape([command] + arguments)
    send(command)
  end

  def create
    Process.setsid("kak", { "-s", name, "-d" })
  end

  def self.create(name)
    new(name).create
  end

  def attach
    Process.run("kak", { "-c", name }, input: :inherit, output: :inherit, error: :inherit)
  end

  def kill
    send("kill")
  end

  def self.all
    output = IO::Memory.new

    Process.run("kak", { "-clear" })
    Process.run("kak", { "-l" }, output: output)

    output.to_s.lines.map do |session_name|
      new(session_name)
    end
  end

  def exists?
    self.class.all.any? do |session|
      session.name == name
    end
  end

  def clients
    get("%val{client_list}").map do |client_name|
      client(client_name)
    end
  end

  def client(name)
    Client.new(self, name)
  end

  def buffers
    get("%val{buflist}").map do |buffer_name|
      buffer(buffer_name)
    end
  end

  def buffer(name)
    Buffer.new(self, name)
  end
end
