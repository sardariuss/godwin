import Model                  "Model";
import Categories             "Categories";
import StatusManager          "StatusManager";
import SubMomentum            "SubMomentum";
import Questions              "questions/Questions";
import QuestionQueriesFactory "questions/QueriesFactory";
import Controller             "controller/Controller";
import Votes                  "votes/Votes";
import VotersHistory          "votes/VotersHistory";
import QuestionVoteJoins      "votes/QuestionVoteJoins";
import Interests              "votes/Interests";
import Categorizations        "votes/Categorizations";
import Opinions               "votes/Opinions";
import Polarization           "votes/representation/Polarization";
import PolarizationMap        "votes/representation/PolarizationMap";
import SubaccountGenerator    "token/SubaccountGenerator";
import TokenInterface         "token/TokenInterface";
import PayForNew              "token/PayForNew";
import StableTypes            "../stable/Types";

import WRef                   "../utils/wrappers/WRef";

module {

  type Question        = StableTypes.Current.Question;
  type Status          = StableTypes.Current.Status;
  type Cursor          = StableTypes.Current.Cursor;
  type Polarization    = StableTypes.Current.Polarization;
  type CursorMap       = StableTypes.Current.CursorMap;
  type PolarizationMap = StableTypes.Current.PolarizationMap;
  type State           = StableTypes.Current.State;

  type Controller      = Controller.Controller;
  
  public func build(state: State) : Controller {

    let master = state.master;
    
    let categories = Categories.build(state.categories);
    
    let questions = Questions.Questions(state.questions);

    let queries = QuestionQueriesFactory.build(state.queries.register);

    let sub_momentum = SubMomentum.build(state.momentum, state.selection_params);

    let token_interface = TokenInterface.build({ master = state.master.v; token = state.token.v; });
    let pay_to_open_question = PayForNew.build(
      token_interface,
      #OPEN_QUESTION,
      state.opened_questions.register,
      state.opened_questions.index,
      state.opened_questions.transactions
    );

    let interest_joins = QuestionVoteJoins.build(state.votes.interest.joins);
    let interest_voters_history = VotersHistory.VotersHistory(state.votes.interest.voters_history, interest_joins);
    
    let interests = Interests.build(
      state.votes.interest.register,
      state.votes.interest.open_by,
      interest_voters_history,
      state.votes.interest.transactions,
      token_interface,
      pay_to_open_question,
      interest_joins,
      queries,
      state.price_params,
      state.creator,
      state.opened_questions.creator_rewards);
    
    let opinion_joins = QuestionVoteJoins.build(state.votes.opinion.joins);
    let opinion_voters_history = VotersHistory.VotersHistory(state.votes.opinion.voters_history, opinion_joins);
    
    let opinions = Opinions.build(
      state.votes.opinion.register,
      opinion_voters_history,
      WRef.WRef(state.votes.opinion.vote_decay_params),
      WRef.WRef(state.votes.opinion.late_ballot_decay_params));
    
    let categorization_joins = QuestionVoteJoins.build(state.votes.categorization.joins);
    let categorization_voters_history = VotersHistory.VotersHistory(state.votes.categorization.voters_history, categorization_joins);
    
    let categorizations = Categorizations.build(
      state.votes.categorization.register,
      categorization_voters_history,
      state.votes.categorization.transactions,
      token_interface,
      categories,
      state.price_params
    );

    let status_manager = StatusManager.build(
      state.status.register,
      interest_joins,
      opinion_joins,
      categorization_joins
    );

    let model = Model.Model(
      WRef.WRef(state.name),
      WRef.WRef(state.master),
      WRef.WRef(state.scheduler_params),
      WRef.WRef(state.selection_params),
      WRef.WRef(state.price_params),
      categories,
      questions,
      status_manager,
      sub_momentum,
      queries,
      interests,
      opinions,
      categorizations,
      interest_joins,
      opinion_joins,
      categorization_joins,
      interest_voters_history,
      opinion_voters_history,
      categorization_voters_history
    );

    let controller = Controller.build(model);

    controller;
  };

};