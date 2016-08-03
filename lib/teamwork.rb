require 'faraday'
require 'faraday_middleware'
require 'json'

module Teamwork

  VERSION = "1.0.5"

  class API

    def initialize(project_name: nil, api_key: nil)
      @project_name = project_name
      @api_key = api_key
      @api_conn = Faraday.new(url: "http://#{project_name}.teamworkpm.net/") do |c|
        c.request :multipart
        c.request :json
        c.request :url_encoded
        c.response :json, content_type: /\bjson$/
        c.adapter :net_http
      end

      @api_conn.headers[:cache_control] = 'no-cache'
      @api_conn.basic_auth(api_key, '')
    end

    def account(request_params)
      response = @api_conn.get "account.json", request_params
      response.body
    end

    def people(request_params = nil)
      response = @api_conn.get "people.json", request_params
      response.body
    end

    def projects(request_params = nil)
      response = @api_conn.get "projects.json", request_params
      response.body
    end

    def project_people(id)
      response = @api_conn.get "projects/#{id}/people.json", nil
      response.body
    end

    def has_person_assigned_to_project(project_id, person_id)
      response = @api_conn.get "projects/#{project_id}/people/#{person_id}.json", nil
      response.body
    end

    def assign_people(id, params)
      @api_conn.put "/projects/#{id}/people.json", params
    end

    def create_person(params)
      @api_conn.post 'people.json', params
    end

    def get_person(person_id, params = nil)
      @api_conn.get "/people/#{person_id}.json", params
    end

    def latestActivity(maxItems: 60, onlyStarred: false)
      request_params = {
        maxItems: maxItems,
        onlyStarred: onlyStarred
      }
      response = @api_conn.get "latestActivity.json", request_params
      response.body
    end

    def get_comment(id)
      response = @api_conn.get "comments/#{id}.json"
      response.body["comment"]
    end

    def companies(params = nil)
      @api_conn.get 'companies.json', params
    end

    def get_people_within_company(company_id, params = nil)
      @api_conn.get "/companies/#{company_id}/people.json", params
    end

    def get_company_id(name)
      Hash[@api_conn.get('companies.json').body["companies"].map { |c| [c['name'], c['id']] }][name]
    end

    def create_company(name)
      @api_conn.post 'companies.json', { company: { name: name } }
    end

    def update_company(company_id, name)
      company = @api_conn.put("companies/#{company_id}.json", {
        "company": {
          id: company_id,
          name: name
        }
      })
    end

    def get_or_create_company(name)
      create_company(name) if !get_company_id(name)
      get_company_id(name)
    end

    def create_project(name, client_name)
      result = {}
      company_id = get_or_create_company(client_name)
      project_id = @api_conn.post('projects.json', {
          project: {
              name: name,
              companyId: company_id,
              "category-id" => '0',
              includePeople: false
          }
      }).headers['id']
      result[:project_id] = project_id
      result[:company_id] = company_id
      result
    end

    def update_project(id, name, client_name, status)
      company_id = get_or_create_company(client_name)
      @api_conn.put("projects/#{id}.json", {
          project: {
              name: name,
              companyId: company_id,
              status: status
          }
      }).status
    end

    def mark_task_completed(project_id, task_id)
      @api_conn.put "tasks/#{task_id}/complete.json", nil
    end

    def retrieve_all_tasks(project_id)
      response = @api_conn.get "projects/#{project_id}/tasks.json", nil
      response.body
    end

    def delete_project(id)
      @api_conn.delete "projects/#{id}.json"
    end

    def attach_post_to_project(title, body, project_id)
      @api_conn.post "projects/#{project_id}/posts.json", { post: { title: title, body: body } }
    end
  end
end


