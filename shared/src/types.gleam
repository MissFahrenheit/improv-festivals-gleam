pub type Festival {
  Festival(
    name: String,
    city: String,
    country: String,
    languages: String,
    date: String,
    webpage: String,
    facebook: String,
    year_month: String,
    continent: Continent,
    image: String,
  )
}

pub type YearCase {
  ThisYear
  NextYear
  Empty
}

pub type Continent {
  Continent(id: String, label: String)
}

pub type Msg {
  UserClickedTab(tab_id: String)
}

pub type Model {
  Model(
    active_tab: String,
    festivals: List(Festival),
    continents: List(Continent),
  )
}
