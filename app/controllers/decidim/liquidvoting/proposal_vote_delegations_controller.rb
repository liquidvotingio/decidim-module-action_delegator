# frozen_string_literal: true

module Decidim
  module Liquidvoting
    class ProposalVoteDelegationsController < Decidim::Proposals::ApplicationController
      before_action :authenticate_user!

      helper_method :proposal, :proposal_path, :proposal_proposal_vote_path

      def create
        enforce_permission_to :vote, :proposal, proposal: proposal

        Decidim::Liquidvoting::Client.create_delegation(
          proposal_url: params[:proposal_url],
          delegator_email: current_user&.email,
          delegate_email: params[:delegate_email]
        )

        @from_proposals_list = params[:from_proposals_list] == "true"
        @proposals = [] + [proposal]

        @lv_state = Decidim::Liquidvoting::Client.current_proposal_state(current_user&.email, params[:proposal_url])
        render "decidim/proposals/proposal_votes/update_buttons_and_counters"
      end

      def index
        respond_to do |format|
          format.html { render html: "<p>placeholder module homepage</p>".html_safe }
        end
      end

      def destroy
        enforce_permission_to :unvote, :proposal, proposal: proposal

        Decidim::Liquidvoting::Client.delete_delegation(
          proposal_url: params[:proposal_url],
          delegator_email: current_user&.email,
          delegate_email: params[:delegate_email]
        )

        @from_proposals_list = params[:from_proposals_list] == "true"
        @proposals = [] + [proposal]

        @lv_state = Decidim::Liquidvoting::Client.current_proposal_state(current_user&.email, params[:proposal_url])
        render "decidim/proposals/proposal_votes/update_buttons_and_counters"
      end

      private

      def proposal
        @proposal ||= Decidim::Proposals::Proposal.where(component: current_component).find(params[:proposal_id])
      end

      # Helpers for cross-engine routing

      def proposal_locator_presenter
        ResourceLocatorPresenter.new(@proposal)
      end

      def proposal_path(_proposal)
        proposal_locator_presenter.path
      end

      def proposal_proposal_vote_path(_ignore)
        "#{proposal_path(nil)}/proposal_vote"
      end
    end
  end
end
