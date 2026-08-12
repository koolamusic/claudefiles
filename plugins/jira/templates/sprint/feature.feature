# The sprint's goal set, as executable acceptance predicates.
#
# Each scenario is one predicate: Given = precondition, When = the operator,
# Then = postcondition. The same triple in three lineages — a BDD scenario,
# a STRIPS operator (precondition/effects), and a Hoare triple {P} C {Q}.
#   https://en.wikipedia.org/wiki/Behavior-driven_development
#   https://en.wikipedia.org/wiki/Hoare_logic
#   https://en.wikipedia.org/wiki/Stanford_Research_Institute_Problem_Solver
#   https://en.wikipedia.org/wiki/Hierarchical_task_network
#
# Rules:
# - Every scenario carries @req:<ID> — domain prefix + sequential, unique per
#   sprint (TOK-01, TOK-02, SES-01). Uppercase, no whitespace. `_halt` reserved.
# - @plan:<ROMAN> / @wave:<N> tag the plan claiming this predicate (its
#   `effects:` frontmatter must list the same ID) and its wave.
# - Declared here once; plans claim by ID, tests and warden sense by ID.
#   Never redeclare an ID elsewhere.
# - Files are lowercase kebab (tok-sessions.feature): lowercase = the contract,
#   UPPERCASE.md = working papers. Frozen at execution time, like CONTEXT.md.

@sprint:<slug>
Feature: <one user-visible capability this sprint delivers>

  @req:TOK-01 @plan:I @wave:1
  Scenario: Expired token is rejected
    Given a session issued more than 24 hours ago
    When the client calls /me with that token
    Then the response status is 401
