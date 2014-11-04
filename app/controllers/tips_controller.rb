class TipsController < ApplicationController

  before_action :load_project

  def index
    if @project
      @tips = @project.tips.includes(:user).with_address
    elsif params[:user_id]
      @user = User.find params[:user_id]
      if @user.present? && @user.bitcoin_address.present?
        @tips = @user.tips.includes(:project)
      else
        flash[:error] = I18n.t('errors.user_not_found')
        redirect_to users_path and return
      end
    else
      @tips = Tip.with_address.includes(:project)
    end
    @tips = @tips.order(created_at: :desc).
                  page(params[:page]).
                  per(params[:per_page] || 30)
    respond_to do |format|
      format.html
      format.csv  { render csv: @tips, except: [:updated_at, :commit, :commit_message, :refunded_at, :decided_at], add_methods: [:user_name, :project_name, :decided?, :claimed?, :paid?, :refunded?, :txid] }
    end
  end


  private

  def load_project
    if params[:project_id].present?
      super params[:project_id]
    elsif params[:service].present? && params[:repo].present?
      super Project.where(host: params[:service]).
                    where('lower(`full_name`) = ?' , params[:repo].downcase).first
    end
  end
end
