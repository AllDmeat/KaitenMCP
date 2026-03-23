import KaitenSDK

struct CardDetailSummary: Encodable, Sendable {
  let id: Int?
  let title: String?
  let description: String?
  let board_id: Int?
  let column_id: Int?
  let lane_id: Int?
  let state: Int?
  let condition: Int?
  let archived: Bool?
  let blocked: Bool?
  let asap: Bool?
  let owner_id: Int?
  let due_date: String?
  let created: String?
  let updated: String?
  let type_id: Int?
  let tag_ids: [Int]?
  let sprint_id: Int?
  let children_count: Int?
  let children_done: Int?
  let parents_count: Int?
  let size_text: String?

  init(card: Components.Schemas.Card) {
    self.id = card.id
    self.title = card.title
    self.description = card.description
    self.board_id = card.board_id
    self.column_id = card.column_id
    self.lane_id = card.lane_id
    self.state = card.state
    self.condition = card.condition
    self.archived = card.archived
    self.blocked = card.blocked
    self.asap = card.asap
    self.owner_id = card.owner_id
    self.due_date = card.due_date
    self.created = card.created
    self.updated = card.updated
    self.type_id = card.type_id
    self.tag_ids = card.tag_ids
    self.sprint_id = card.sprint_id
    self.children_count = card.children_count
    self.children_done = card.children_done
    self.parents_count = card.parents_count
    self.size_text = card.size_text
  }
}
