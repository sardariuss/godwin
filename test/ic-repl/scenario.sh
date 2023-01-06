#!/usr/local/bin/ic-repl

load "common/install.sh";

//identity default;
//
//// Install the backend canister
//let arguments = record {
//  scheduler = record {
//    selection_rate = variant { SECONDS = 0 };
//    interest_duration = variant { DAYS = 1 };
//    opinion_duration = variant { SECONDS = 0 };
//    categorization_duration = variant { SECONDS = 0 };
//    rejected_duration = variant { SECONDS = 0 };
//  };
//  categories = vec {
//    "IDENTITY";
//    "COOPERATION";
//  };
//};
//
//let backend = installBackend(arguments);

// To use instead if wish to use the deployed backend
identity default "~/.config/dfx/identity/default/identity.pem";
import backend = "rrkah-fqaaa-aaaaa-aaaaq-cai";

// @todo: one should not be able to ask a question as the anonymous user "2vxsx-fae"
// @todo: find a way to test partial vec to uncomment the tests on current stage

"Create candidate questions";
call backend.createQuestions(vec {
  "One is not born, but rather becomes, a woman.";
  "Differences in treatment and quality of life in our society show that racism is still omnipresent.";
  "All sciences, even chemistry and biology are not uncompromising and are conditioned by our society.";
  "The categories “women” and “men” are social constructs that should be given up.";
  "Nobody is by nature predisposed to criminality.";
  "Sexual orientation is a social construct";
  "Social differences between ethnic groups cannot be explained by biology.";
  "The social roles of women and men can partly be explained by biological differences.";
  "Hormonal differences can explain some differences in individual characteristics between women and men.";
  "Sexual assaults are partly caused by natural impulse.";
  "Transgender individuals will never really be of the gender they identify as.";
  "Members of a nation or culture have some unchangeable characteristics that define them.";
  "Biologically, human beings are meant for heterosexuality.";
  "Selfishness is the overriding drive in the human species, no matter the context.";
  "Borders should eventually be abolished.";
  "People need to stand up for their ideals, even if it leads them to betray their country.";
  "My country must pay for the damages caused by the crimes it committed in other countries.";
  "If two countries have similar economies, social systems and environmental norms, then the free market between them has no negative impact.";
  "National Chauvinism during sports competitions is not acceptable.";
  "I am equally concerned about the inhabitants of my country and those of other the countries.";
  "Foreigners living in my country should be allowed to act politically, equally to those who have the nationality.";
  "Citizens should take priority over foreigners.";
  "The values of my country are superior to those of other countries.";
  "Multiculturalism is a threat to our society.";
  "A good citizen is a patriot.";
  "It is legitimate for a country to intervene militarily to defend its economic interests.";
  "It is necessary to teach history in order to create a sense of belonging to the nation.";
  "Research produced by my country should not be available to other countries.";
  "No one should get rich from owning a business, housing, or land.";
  "Wage labor is a form of theft from the worker by companies.";
  "It is important that health should stay a public matter.";
  "Energy and transport structures should be a public matter.";
  "Patents should not exist.";
  "It is necessary to implement assemblies to ration our production to the consumers according to their needs.";
  "The labor market enslaves workers.";
  "Looking for one\'s own profit is healthy for the economy.";
  "It is merit that explains differences of wealth between two individuals.";
  "The fact that some schools and universities are private is not a problem.";
  "Offshoring and outsourcing are necessary evils to improve production.";
  "It is acceptable that there are rich and poor people.";
  "It is acceptable that some industry sectors are private.";
  "Banks should remain private.";
  "Revenues and capital should be taxed to redistribute wealth.";
  "We should be retiring earlier.";
  "Dismissals of employees should be forbidden except if it is justified.";
  "Minimal levels of salary should be ensured to make sure that a worker can live of their work.";
  "It is necessary to avoid private monopoly.";
  "Loans contracted by the public sector (states, regions, communities) do not necessarily have to be repaid.";
  "Some sectors or type of employment should be financially supported.";
  "Market economy is optimal when it is not regulated."
}, variant { CANDIDATE });

"Create open opinion questions";
call backend.createQuestions(vec {
  "Nowadays employees are free to choose when signing a contract with their future employer";
  "It is necessary to remove regulations in labor legislation to encourage firms to hire.";
  "The maximum allowed hours in the legal work week should be increased.";
  "Environmental norms should be influenced by mass consumption and not from an authority.";
  "Social assistance deters people from working.";
  "State-run companies should be managed like private ones and follow the logic of the market (competition, profitability...).";
  "Traditions should be questioned.";
  "I do not have any problem if other official languages are added or replace the already existing official language in my country.";
  "Marriage should be abolished.";
  "Foreigners enrich our culture.";
  "The influence of religion should decrease.";
  "A language is defined by its users, not by scholars.";
  "Euthanasia should be authorized.";
}, variant { OPEN = variant { OPINION } });

"Create open categorization questions";
call backend.createQuestions(vec {
  "Homosexuals should not be treated equally to heterosexuals in regards to marriage, parentage, adoption or procreation.";
  "In some specific conditions the death penalty is justified.";
  "Technological progress must not change society too quickly.";
  "School should mostly teach our values, traditions, and fundamental knowledge.";
  "Abortion should be limited to specific cases.";
  "The main goal of a couple is to make at least one child.";
  "Abstinence should be preferred to contraception, to preserve the true nature of the sexual act.";
  "It is not acceptable that human actions should lead to the extinction of species.";
  "GMOs should be forbidden outside research and medical purposes.";
  "We must fight against global warming.";
  "We should accept changes in our way of consuming food to limit the exploitation of nature.";
}, variant { OPEN = variant { CATEGORIZATION } });

"Create closed questions";
call backend.createQuestions(vec {
  "It is important to encourage an agriculture that maintains a food biodiversity, even if the output is inferior.";
  "Preserving non-urban ecosystems is more important than creating jobs.";
  "Reduction of waste should be done by reducing production.";
  "Space colonization is a good solution for supplying the lack of raw material on Earth (iron, rare metals, fuel...)";
  "Transforming ecosystems durably to increase the quality of life of human beings is legitimate.";
  "It is necessary to massively invest in research to improve productivity.";
  "Transhumanism will be beneficial because it will allow us to improve our capacities.";
  "Nuclear fission, when well maintained, is a good source of energy.";
  "Exploitation of fossil fuels is necessary.";
  "Maintaining strong economic growth should be an objective for the government.";
  "Prisons should no longer exist.";
  "It is unfair to set a minimal penalty for an offense or a crime.";
  "Individuals who get out of prison should be assisted in their reinsertion.";
  "Justice should always take into consideration the context and the past of the condemned and adapt their penalty accordingly.";
  "Conditions of life in jail should be greatly improved.";
  "The filing and storage of personal records should be delimited strictly and database cross-checking should be forbidden.";
  "The right to be anonymous on Internet should be guaranteed.";
  "The purpose of the judiciary system should be to punish those who went against the law.";
  "The police should be armed.";
  "The sacrifice of some civil liberties is a necessity in order to be protected from terrorist acts.";
  "Order and authority should be respected in all circumstances.";
  "Heavy penalties are efficient because they are dissuasive.";
  "It is better to arrest someone potentially dangerous preemptively rather than taking the risk of having them committing a crime.";
  "Mass strike is a good way to acquire new rights.";
  "Armed struggle in a country is sometimes necessary.";
  "Insurrection is necessary to deeply change society.";
  "Activism in existing political organizations is not relevant to change society.";
  "Elections organized by the state cannot question the powers in place.";
}, variant { CLOSED });

"Create rejected questions";
call backend.createQuestions(vec {
  "Hacking has a legitimate place in political struggle.";
  "Sabotage is legitimate under certain conditions.";
  "Activists must always act in strict accordance with the law.";
  "Revolutions will always end up in a bad way.";
  "Changing the system radically is counter-productive. We should rather transform it progressively.";
  "Violence against individuals is never productive.";
  "We should always distance ourselves from protesters who use violence.";
  "We need to make compromises with the opposition to apply our ideas.";
  "Changes in an individual\'s way of life can induce changes in society.";
  "My religion must be spread as widely as possible.";
  "It is a small group that consciously and secretly controls the world.";
  "A good policy is a pragmatic policy without ideology.";
  "We need to establish a monarchy to federate the people and preserve our sovereignty.";
  "Humans should neither eat nor exploit animals.";
  "The state should be abolished.";
}, variant { REJECTED });