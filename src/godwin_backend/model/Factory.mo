import VoteTypes              "votes/Types";
import QuestionTypes          "questions/Types";
import PayRules               "PayRules";
import State                  "State";
import Model                  "Model";
import Categories             "Categories";
import Facade                 "Facade";
import StatusManager          "questions/StatusManager";
import Questions              "questions/Questions";
import QuestionQueriesFactory "questions/QueriesFactory";
import Controller             "controller/Controller";
import Votes                  "votes/Votes";
import QuestionVoteJoins      "votes/QuestionVoteJoins";
import Interests              "votes/Interests";
import Categorizations        "votes/Categorizations";
import Opinions               "votes/Opinions";
import Polarization           "votes/representation/Polarization";
import PolarizationMap        "votes/representation/PolarizationMap";
import SubaccountGenerator    "token/SubaccountGenerator";
import TokenInterface         "token/TokenInterface";
import PayForNew              "token/PayForNew";

module {

  type Question        = QuestionTypes.Question;
  type Status          = QuestionTypes.Status;
  type Cursor          = VoteTypes.Cursor;
  type Polarization    = VoteTypes.Polarization;
  type CursorMap       = VoteTypes.CursorMap;
  type PolarizationMap = VoteTypes.PolarizationMap;
  type Facade          = Facade.Facade;
  type State           = State.State;

  public func build(state: State) : Facade {

    let master = state.master;
    
    let categories = Categories.build(state.categories);
    
    let questions = Questions.Questions(state.questions);

    let status_manager = StatusManager.build(state.status.register);

    let queries = QuestionQueriesFactory.build(state.queries.register);

    let pay_rules = PayRules.build(state.price_parameters);

    let token_interface = TokenInterface.build(state.master.v);
    let pay_to_open_question = PayForNew.build(
      token_interface,
      #OPEN_QUESTION,
      state.opened_questions.register,
      state.opened_questions.index,
      state.opened_questions.transactions
    );

    let interest_join = QuestionVoteJoins.build(state.joins.interests);
    
    let interests = Interests.build(
      state.votes.interest.register,
      state.votes.interest.transactions,
      token_interface,
      pay_to_open_question,
      interest_join,
      queries,
      pay_rules
    );
    
    let opinion_join = QuestionVoteJoins.build(state.joins.opinions);
    
    let opinions = Opinions.build(
      state.votes.opinion.register
    );
    
    let categorization_join = QuestionVoteJoins.build(state.joins.categorizations);
    
    let categorizations = Categorizations.build(
      state.votes.categorization.register,
      state.votes.categorization.transactions,
      token_interface,
      categories,
      pay_rules
    );

    let model = Model.build(
      state.name,
      state.master,
      state.controller.model.last_pick_date,
      state.controller.model.params,
      categories,
      questions,
      status_manager,
      queries,
      interests,
      opinions,
      categorizations,
      interest_join,
      opinion_join,
      categorization_join
    );

    let controller = Controller.build(model);

    let facade = Facade.Facade(controller);

    facade;
  };

};