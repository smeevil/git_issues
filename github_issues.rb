require 'rubygems'
require 'active_support'
require 'net/http'

class Github
  attr_accessor :site, :user, :token, :repo, :format

  def initialize(options=Hash.new)
    @format=options[:format]||"xml"
    @site="http://github.com/"
    read_gitconfig

  end

  def read_gitconfig
    config = {}
    group = nil
    File.foreach("#{ENV['HOME']}/.gitconfig") do |line|
      line.strip!
      if line[0] != ?# && line =~ /\S/
        if line =~ /^\[(.*)\]$/
          group = $1
          config[group] ||= {}
        else
          key, value = line.split("=").map { |v| v.strip }
          config[group][key] = value
        end
      end
    end
    self.user=config["github"]["user"]
    self.token=config["github"]["token"]
  end
  def repos
    url = URI.parse(self.site)
    res = Net::HTTP.start(url.host, url.port) {|http| http.get("/api/v2/#{self.format}/repos/show/#{self.user}?login=#{self.user}&token=#{self.token}") }
    repos=Hash.from_xml(res.body)["repositories"]
  end
end

class Issue < Github
  attr_accessor :repo
  def initialize(options)
    @repo=options[:repo]
    super
  end

  def list
    url = URI.parse(self.site)
    res = Net::HTTP.start(url.host, url.port) {|http| http.get("/api/v2/#{self.format}/issues/list/#{self.user}/#{self.repo}/open?login=#{self.user}&token=#{self.token}") }
    issues=Hash.from_xml(res.body)["issues"]
  end

  def show(nr)
    url = URI.parse(self.site)
    res = Net::HTTP.start(url.host, url.port) {|http| http.get("/api/v2/#{self.format}/issues/show/#{self.user}/#{self.repo}/#{nr}?login=#{self.user}&token=#{self.token}") }
    issue=Hash.from_xml(res.body)["issue"]
  end

  def open(options)
    url = URI.parse("#{self.site}api/v2/#{self.format}/issues/open/#{self.user}/#{self.repo}")
    puts url.inspect
    res = Net::HTTP.post_form(url,{
      'login'=>self.user,
      'token'=>self.token,
      'title'=>options[:title],
      'body'=>options[:body]
      }
    )
    puts res.body
  end
  
  def close(nr)
    url = URI.parse(self.site)
    res = Net::HTTP.start(url.host, url.port) {|http| http.get("/api/v2/#{self.format}/issues/close/#{self.user}/#{self.repo}/#{nr}?login=#{self.user}&token=#{self.token}") }
    issues=Hash.from_xml(res.body)["issues"]
  end
  
  def comment(options)
    url = URI.parse("#{self.site}api/v2/#{self.format}/issues/comment/#{self.user}/#{self.repo}/#{options[:nr]}")
    puts url.inspect
    res = Net::HTTP.post_form(url,{
      'login'=>self.user,
      'token'=>self.token,
      'comment'=>options[:comment]
      }
    )
    puts res.body
  end
end

git=Github.new

# git.repos.each do |repo|
#   puts "#{repo["name"]} #{repo["open_issues"]}"
# end

# issues=Issue.new(:repo=>"git_issues")
# issues.list.each do |issue|
#   puts "#{issue["title"]} by #{issue["user"]}"
# end

# issue=Issue.new(:repo=>"git_issues")
# issue=issue.show(2)
# puts "#{issue["title"]} by #{issue["user"]}"
# puts issue["body"]

# issue=Issue.new(:repo=>"git_issues")
# issue.open(:title=>"New issue by api", :body=>"This should be the body\n thats awesome is it not ?")

# issue=Issue.new(:repo=>"git_issues")
# issue.close(3)

issue=Issue.new(:repo=>"git_issues")
issue.comment(:nr=>2,:comment=>"Just a comment by the api\n awesome isn't it ?")
