# encoding: utf-8

module Github
  class Repos < API
    extend AutoloadHelper

    # Load all the modules after initializing Repos to avoid superclass mismatch
    autoload_all 'github_api/repos',
      :Collaborators => 'collaborators',
      :Comments      => 'comments',
      :Commits       => 'commits',
      :Contents      => 'contents',
      :Downloads     => 'downloads',
      :Forks         => 'forks',
      :Hooks         => 'hooks',
      :Keys          => 'keys',
      :Merging       => 'merging',
      :PubSubHubbub  => 'pub_sub_hubbub',
      :Statuses      => 'statuses'

    DEFAULT_REPO_OPTIONS = {
      "homepage"   => "https://github.com",
      "private"    => false,
      "has_issues" => true,
      "has_wiki"   => true,
      "has_downloads" => true
    }.freeze

    REQUIRED_REPO_OPTIONS = %w[ name ]

    VALID_REPO_OPTIONS = %w[
      name
      description
      homepage
      private
      has_issues
      has_wiki
      has_downloads
      team_id
      auto_init
      gitignore_template
    ].freeze

    VALID_REPO_TYPES = %w[ all public private member ].freeze

    # Creates new Repositories API
    def initialize(options = {})
      super(options)
    end

    # Access to Repos::Collaborators API
    def collaborators
      @collaborators ||= ApiFactory.new 'Repos::Collaborators'
    end

    # Access to Repos::Comments API
    def comments
      @commits ||= ApiFactory.new 'Repos::Comments'
    end

    # Access to Repos::Commits API
    def commits
      @commits ||= ApiFactory.new 'Repos::Commits'
    end

    # Access to Repos::Contents API
    def contents
      @contents ||= ApiFactory.new 'Repos::Contents'
    end

    # Access to Repos::Downloads API
    def downloads
      @downloads ||= ApiFactory.new 'Repos::Downloads'
    end

    # Access to Repos::Forks API
    def forks
      @forks ||= ApiFactory.new 'Repos::Forks'
    end

    # Access to Repos::Hooks API
    def hooks
      @hooks ||= ApiFactory.new 'Repos::Hooks'
    end

    # Access to Repos::Keys API
    def keys
      @keys ||= ApiFactory.new 'Repos::Keys'
    end

    # Access to Repos::Merging API
    def merging
      @mergin ||= ApiFactory.new 'Repos::Merging'
    end

    # Access to Repos::PubSubHubbub API
    def pubsubhubbub
      @pubsubhubbub ||= ApiFactory.new 'Repos::PubSubHubbub'
    end

    # Access to Repos::Statuses API
    def statuses
      @statuses ||= ApiFactory.new 'Repos::Statuses'
    end

    # List repositories for the authenticated user
    #
    # = Examples
    #   github = Github.new :oauth_token => '...'
    #   github.repos.list
    #   github.repos.list { |repo| ... }
    #
    # List public repositories for the specified user.
    #
    # = Examples
    #   github = Github.new
    #   github.repos.list user: 'user-name'
    #   github.repos.list user: 'user-name' { |repo| ... }
    #
    #   github.repos(user: 'user-name').list
    #   github.repos(user: 'user-name').list { |repo| ... }
    #
    # List repositories for the specified organisation.
    #
    # = Examples
    #  github = Github.new
    #  github.repos.list :org => 'org-name'
    #  github.repos.list :org => 'org-name', { |repo| ... }
    #
    def list(*args)
      arguments(self).parse *args do |args|
        args.sift %w[ user org type sort direction ]
      end
      params = arguments.params

      response = if (user_name = (params.delete("user") || user))
        get_request("/users/#{user_name}/repos", params)
      elsif (org_name = (params.delete("org") || org))
        get_request("/orgs/#{org_name}/repos", params)
      else
        # For authenticated user
        get_request("/user/repos", params)
      end
      return response unless block_given?
      response.each { |el| yield el }
    end
    alias :all :list

    # Get a repository
    #
    # = Examples
    #  github = Github.new
    #  github.repos.get 'user-name', 'repo-name'
    #  github.repos.get user: 'user-name', repo: 'repo-name'
    #  github.repos(user: 'user-name', repo: 'repo-name').get
    #
    def get(*args)
      arguments(self, :args_required => [:user, :repo]).parse *args
      params = arguments.params

      get_request("/repos/#{user}/#{repo}", params)
    end
    alias :find :get

    # Create a new repository for the autheticated user.
    #
    # = Parameters
    #  <tt>:name</tt> - Required string
    #  <tt>:description</tt> - Optional string
    #  <tt>:homepage</tt> - Optional string
    #  <tt>:private</tt> - Optional boolean - <tt>true</tt> to create a private repository, <tt>false</tt> to create a public one.
    #  <tt>:has_issues</tt> - Optional boolean - <tt>true</tt> to enable issues for this repository, <tt>false</tt> to disable them
    #  <tt>:has_wiki</tt> - Optional boolean - <tt>true</tt> to enable the wiki for this repository, <tt>false</tt> to disable it. Default is <tt>true</tt>
    #  <tt>:has_downloads</tt> Optional boolean - <tt>true</tt> to enable downloads for this repository
    #  <tt>:org</tt> Optional string - The organisation in which this repository will be created
    #  <tt>:team_id</tt> Optional number - The id of the team that will be granted access to this repository. This is only valid when creating a repo in an organization
    #
    # = Examples
    #  github = Github.new
    #  github.repos.create "name": 'repo-name'
    #    "description": "This is your first repo",
    #    "homepage": "https://github.com",
    #    "private": false,
    #    "has_issues": true,
    #    "has_wiki": true,
    #    "has_downloads": true
    #
    # Create a new repository in this organisation. The authenticated user
    # must be a member of this organisation
    #
    # Examples:
    #   github = Github.new :oauth_token => '...'
    #   github.repos.create :name => 'repo-name', :org => 'organisation-name'
    #
    def create(*args)
      arguments(self).parse *args do
        sift VALID_REPO_OPTIONS + %w[ org ]
        assert_required %w[ name ]
      end
      params = arguments.params

      # Requires authenticated user
      if (org = params.delete("org"))
        post_request("/orgs/#{org}/repos", DEFAULT_REPO_OPTIONS.merge(params))
      else
        post_request("/user/repos", DEFAULT_REPO_OPTIONS.merge(params))
      end
    end

    # Delete a repository
    #
    # Deleting a repository requires admin access.
    # If OAuth is used, the delete_repo scope is required.
    #
    # = Examples
    #  github = Github.new :oauth_token => '...'
    #  github.repos.delete 'user-name', 'repo-name'
    #
    def delete(*args)
      arguments(self, :args_required => [:user, :repo]).parse *args
      params = arguments.params

      delete_request("/repos/#{user}/#{repo}", params)
    end
    alias :remove :delete

    # List contributors
    #
    # = Parameters
    #  <tt>:anon</tt> - Optional flag. Set to 1 or true to include anonymous contributors.
    #
    # = Examples
    #
    #  github = Github.new
    #  github.repos.contributors 'user-name','repo-name'
    #  github.repos.contributors 'user-name','repo-name' { |cont| ... }
    #
    def contributors(*args)
      arguments(self, :args_required => [:user, :repo]).parse *args do
        sift %w[ anon ]
      end
      params = arguments.params

      response = get_request("/repos/#{user}/#{repo}/contributors", params)
      return response unless block_given?
      response.each { |el| yield el }
    end
    alias :list_contributors :contributors
    alias :contribs :contributors

    # Edit a repository
    #
    # = Parameters
    # * <tt>:name</tt> Required string
    # * <tt>:description</tt>   Optional string
    # * <tt>:homepage</tt>      Optional string
    #  <tt>:private</tt> - Optional boolean - <tt>false</tt> to create public reps, <tt>false</tt> to create a private one
    # * <tt>:has_issues</tt>    Optional boolean - <tt>true</tt> to enable issues for this repository, <tt>false</tt> to disable them
    # * <tt>:has_wiki</tt>      Optional boolean - <tt>true</tt> to enable the wiki for this repository, <tt>false</tt> to disable it. Default is <tt>true</tt>
    # * <tt>:has_downloads</tt> Optional boolean - <tt>true</tt> to enable downloads for this repository
    #
    # = Examples
    #
    #  github = Github.new
    #  github.repos.edit 'user-name', 'repo-name',
    #    :name => 'hello-world',
    #    :description => 'This is your first repo',
    #    :homepage => "https://github.com",
    #    :public => true, :has_issues => true
    #
    def edit(*args)
      arguments(self, :args_required => [:user, :repo])
      arguments.parse *args do
        sift VALID_REPO_OPTIONS
        assert_required %w[ name ]
      end
      params = arguments.params

      patch_request("/repos/#{user}/#{repo}", DEFAULT_REPO_OPTIONS.merge(params))
    end

    # Delete a repository
    #
    # Deleting a repository requires admin access.
    # If OAuth is used, the delete_repo scope is required.
    #
    # = Examples
    #  github = Github.new :oauth_token => '...'
    #  github.repos.delete 'user-name', 'repo-name'
    #
    def delete(*args)
      arguments(self, :args_required => [:user, :repo]).parse *args
      params = arguments.params

      delete_request("/repos/#{user}/#{repo}", params)
    end
    alias :remove :delete

    # List branches
    #
    # = Examples
    #
    #   github = Github.new
    #   github.repos.branches 'user-name', 'repo-name'
    #   github.repos(user: 'user-name', repo: 'repo-name').branches
    #
    #   repos = Github::Repos.new
    #   repos.branches 'user-name', 'repo-name'
    #
    # def branches(user_name, repo_name, params={})
    def branches(*args)
      arguments(self, :args_required => [:user, :repo]).parse *args
      params = arguments.params

      response = get_request("/repos/#{user}/#{repo}/branches", arguments.params)
      return response unless block_given?
      response.each { |el| yield el }
    end
    alias :list_branches :branches

    # Get branch
    #
    # = Examples
    #
    #   github = Github.new
    #   github.repos.branch 'user-name', 'repo-name', 'branch-name'
    #   github.repos.branch user: 'user-name', repo: 'repo-name', branch: 'branch-name'
    #   github.repos(user: 'user-name', repo: 'repo-name', branch: 'branch-name').branch
    #
    def branch(*args)
      arguments(self, :args_required => [:user, :repo, :branch]).parse *args
      params = arguments.params

      get_request("repos/#{user}/#{repo}/branches/#{branch}", params)
    end

    # List contributors
    #
    # = Parameters
    #  <tt>:anon</tt> - Optional flag. Set to 1 or true to include anonymous contributors.
    #
    # = Examples
    #
    #  github = Github.new
    #  github.repos.contributors 'user-name','repo-name'
    #  github.repos.contributors 'user-name','repo-name' { |cont| ... }
    #
    def contributors(*args)
      arguments(self, :args_required => [:user, :repo])
      arguments.parse *args do |args|
        args.sift ['anon']
      end
      params = arguments.params

      response = get_request("/repos/#{user}/#{repo}/contributors", params)
      return response unless block_given?
      response.each { |el| yield el }
    end
    alias :list_contributors :contributors
    alias :contribs :contributors

    # List languages
    #
    # = Examples
    #  github = Github.new
    #  github.repos.languages 'user-name', 'repo-name'
    #  github.repos.languages 'user-name', 'repo-name' { |lang| ... }
    #
    def languages(*args)
      arguments(self, :args_required => [:user, :repo]).parse *args
      params = arguments.params

      response = get_request("/repos/#{user}/#{repo}/languages", params)
      return response unless block_given?
      response.each { |el| yield el }
    end
    alias :list_languages :languages

    # List tags
    #
    # = Examples
    #   github = Github.new
    #   github.repos.tags 'user-name', 'repo-name'
    #   github.repos.tags 'user-name', 'repo-name' { |tag| ... }
    #
    def tags(*args)
      arguments(self, :args_required => [:user, :repo]).parse *args
      params = arguments.params

      response = get_request("/repos/#{user}/#{repo}/tags", params)
      return response unless block_given?
      response.each { |el| yield el }
    end
    alias :list_tags :tags
    alias :repo_tags :tags
    alias :repository_tags :tags

    # List teams
    #
    # == Examples
    #   github = Github.new
    #   github.repos.teams 'user-name', 'repo-name'
    #   github.repos.teams 'user-name', 'repo-name' { |team| ... }
    #
    #   github.repos(user: 'user-name, repo: 'repo-name').teams
    #
    def teams(*args)
      arguments(self, :args_required => [:user, :repo]).parse *args
      params = arguments.params

      response = get_request("/repos/#{user}/#{repo}/teams", params)
      return response unless block_given?
      response.each { |el| yield el }
    end
    alias :list_teams :teams
    alias :repo_teams :teams
    alias :repository_teams :teams

  end # Repos
end # Github
