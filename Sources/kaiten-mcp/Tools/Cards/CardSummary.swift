import KaitenSDK

struct CardSummary: Encodable, Sendable {
  let id: Int?
  let title: String?
  let column_id: Int?
  let lane_id: Int?
  let owner_id: Int?
  let due_date: String?
  let tag_ids: [Int]?

  init(card: Components.Schemas.Card) {
    self.id = card.id
    self.title = card.title
    self.column_id = card.column_id
    self.lane_id = card.lane_id
    self.owner_id = card.owner_id
    self.due_date = card.due_date
    self.tag_ids = card.tag_ids
  }
}
