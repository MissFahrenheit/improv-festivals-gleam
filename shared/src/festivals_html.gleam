import festival as festival_shared
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import icons
import lustre/attribute as attr
import lustre/element.{type Element}
import lustre/element/html.{html}
import lustre/event
import types.{type Continent, type Festival}

pub fn festival_to_html(
  festivals: List(Festival),
  continents: List(Continent),
  app_url: String,
) -> Element(types.Msg) {
  let assert Ok(first_continent) = list.first(continents)
  let model =
    types.Model(
      active_tab: first_continent.id,
      festivals: festivals,
      continents: continents,
    )
  html([], [
    html.head([], [
      html.meta([attr.charset("utf-8")]),
      html.meta([
        attr.content("width=device-width, initial-scale=1"),
        attr.name("viewport"),
      ]),
      html.title([], "Improv Festivals Worldwide"),

      html.meta([
        attr.content(
          "An open-source project that transforms a shared spreadsheet into a live directory of improv festivals around the world.",
        ),
        attr.name("description"),
      ]),
      html.meta([
        attr.content("Improv Festivals Worldwide"),
        attr.attribute("property", "og:title"),
      ]),
      html.meta([
        attr.content(
          "An open-source project that transforms a shared spreadsheet into a live directory of improv festivals around the world.",
        ),
        attr.attribute("property", "og:description"),
      ]),
      html.meta([
        attr.content("website"),
        attr.attribute("property", "og:type"),
      ]),
      html.meta([
        attr.content(app_url),
        attr.attribute("property", "og:url"),
      ]),
      html.meta([
        attr.content("static/assets/img/improv_festivals_worldwide.png"),
        attr.attribute("property", "og:image"),
      ]),
      html.meta([attr.content("website"), attr.name("twitter:card")]),
      html.meta([
        attr.content("Improv Festivals Worldwide"),
        attr.name("twitter:title"),
      ]),
      html.meta([
        attr.content(
          "An open-source project that transforms a shared spreadsheet into a live directory of improv festivals around the world.",
        ),
        attr.name("twitter:description"),
      ]),
      html.meta([
        attr.content("static/assets/img/improv_festivals_worldwide.png"),
        attr.name("twitter:image"),
      ]),

      html.link([
        attr.attribute("sizes", "96x96"),
        attr.href("static/favicon-96x96.png"),
        attr.type_("image/png"),
        attr.rel("icon"),
      ]),
      html.link([
        attr.href("static/favicon.ico"),
        attr.rel("shortcut icon"),
      ]),
      html.link([
        attr.href("static/apple-touch-icon.png"),
        attr.attribute("sizes", "180x180"),
        attr.rel("apple-touch-icon"),
      ]),
      html.meta([
        attr.content("Radical Elements"),
        attr.name("apple-mobile-web-app-title"),
      ]),
      html.link([
        attr.href("static/favicon.svg"),
        attr.type_("image/svg+xml"),
        attr.rel("icon"),
      ]),
      html.link([
        attr.href("static/site.webmanifest"),
        attr.rel("manifest"),
      ]),

      html.link([
        attr.href("static/assets/css/app.css"),
        attr.rel("stylesheet"),
      ]),
      html.script(
        [attr.type_("application/json"), attr.id("model")],
        model_to_json(model.active_tab, model.festivals, model.continents),
      ),
    ]),
    html.body([], [
      html.div([attr.id("app")], [view(model)]),
      html.script([attr.src("static/front.js")], ""),
    ]),
  ])
}

pub fn view(model: types.Model) -> element.Element(types.Msg) {
  html.div([], [
    header(),
    html.main([], [
      tabs_buttons(model),
      html.div(
        [attr.class("pt-3 pt-lg-4 pb-5")],
        list.map(model.continents, continent_tab(_, model)),
      ),
    ]),
    footer(),
  ])
}

fn continent_tab(continent: Continent, model: types.Model) -> Element(b) {
  let active_class = case model.active_tab == continent.id {
    True -> "active"
    False -> ""
  }

  html.div(
    [
      attr.class("tab-content " <> active_class),
      attr.id(continent.id <> "-content"),
      attr.data("content-continent", continent.id),
    ],
    continent_festivals_or_empty_text(continent, model.festivals),
  )
}

fn continent_festivals_or_empty_text(
  continent: Continent,
  festivals: List(Festival),
) -> List(Element(c)) {
  let continent_festivals =
    list.filter(festivals, fn(festival) {
      festival.continent.id == continent.id
    })
  case list.is_empty(continent_festivals) {
    False -> [
      html.div(
        [attr.class("gap-3 gap-lg-4 px-2 px-lg-4 grid m-auto")],
        list.map(continent_festivals, festival_card),
      ),
    ]
    True -> [
      html.p([attr.class("text-center")], [
        html.text("No festivals found in this location or category."),
      ]),
    ]
  }
}

fn get_year(year_month: String) -> String {
  result.unwrap(
    year_month
      |> string.split("-")
      |> list.first,
    "",
  )
}

fn facebook_section(festival: Festival) -> Element(d) {
  let facebook_div =
    html.div([attr.class("flex align-items-center mb-2 info-row")], [
      icons.get("facebook-logo"),
      html.a(
        [
          attr.class("ml-2"),
          attr.href(festival.facebook),
          attr.target("_blank"),
          attr.title(festival.name <> " facebook page"),
        ],
        [html.text("Facebook page")],
      ),
    ])

  let empty_div = html.div([], [])

  case
    string.contains(festival.facebook, "facebook.com"),
    string.contains(festival.facebook, "fb.com")
  {
    False, False -> empty_div
    _, _ -> facebook_div
  }
}

fn festival_card(festival: Festival) -> element.Element(a) {
  html.div([attr.class("grid-item")], [
    html.div([attr.class("p-4 card")], [
      html.div(
        [
          attr.class(
            "flex align-items-center justify-content-between mb-4 gap-3 date-img",
          ),
        ],
        [
          html.div(
            [
              attr.class(
                "flex align-items-center gap-2 date flex-grow-1 flex-shrink-0",
              ),
            ],
            [
              icons.get("calendar"),
              html.span([], [
                html.text(festival.date),
                html.text(case string.is_empty(get_year(festival.year_month)) {
                  False -> ", " <> get_year(festival.year_month)
                  True -> ""
                }),
              ]),
            ],
          ),
          html.img([
            attr.class("festival-image flex-shrink-1"),
            attr.src(festival.image),
          ]),
        ],
      ),
      html.h2([attr.class("mt-1 mb-3")], [html.text(festival.name)]),
      html.div([attr.class("flex align-items-center mb-2 info-row")], [
        icons.get("translate"),
        html.span([attr.class("ml-2")], [html.text(festival.languages)]),
      ]),
      facebook_section(festival),
      html.div([attr.class("flex align-items-center mb-4 info-row")], [
        icons.get("globe"),
        html.a(
          [
            attr.class("ml-2"),
            attr.href(festival.webpage),
            attr.target("_blank"),
            attr.title(festival.name <> " website"),
          ],
          [html.text(festival.webpage)],
        ),
      ]),
      html.div([attr.class("flex align-items-center justify-content-end")], [
        html.div(
          [attr.class("flex align-items-center px-3 py-2 pill location")],
          [
            icons.get("pin"),
            html.span([attr.class("ml-1")], [
              html.text(festival.city <> ", " <> festival.country),
            ]),
          ],
        ),
      ]),
    ]),
  ])
}

fn tabs_buttons(model: types.Model) -> element.Element(types.Msg) {
  html.div(
    [
      attr.class(
        "flex align-items-center justify-content-center px-2 px-lg-4 mb-4",
      ),
    ],
    [
      html.nav(
        [
          attr.class(
            "flex flex-wrap justify-content-center align-items-center py-2 gap-2 px-lg-3",
          ),
        ],
        list.map(model.continents, continent_tab_button(_, model)),
      ),
    ],
  )
}

fn header() -> element.Element(types.Msg) {
  html.header([attr.class("text-center mb-4 mb-lg-5 pt-3 px-2")], [
    html.h1([], [html.text("Improv Festivals Worldwide")]),
    html.p([], [
      html.strong([], [html.text("Improvisers are awesome.")]),
      html.br([]),
      html.text("They maintain a "),
      html.a(
        [
          attr.href(
            "https://docs.google.com/spreadsheets/d/1uIyvbpZsPtWmJZJwSlAEG22A8qcozKmK9WuxRYSIOSY/edit",
          ),
          attr.target("_blank"),
          attr.title("Improv Festivals Worlwide Google Sheet"),
        ],
        [html.text("shareable spreadsheet")],
      ),
      html.text(" of most improv festivals in the world."),
      html.br([]),
      html.text("This "),
      html.a(
        [
          attr.href(
            "https://github.com/MissFahrenheit/improv-festivals-worldwide",
          ),
          attr.target("_blank"),
          attr.title("Improv Festivals Worldwide Project Github page"),
        ],
        [html.text("open-source project")],
      ),
      html.text(
        " ✨magically✨ turns that spreadsheet into a website (refreshes hourly).",
      ),
    ]),
  ])
}

fn footer() -> element.Element(types.Msg) {
  html.footer([attr.class("text-center pb-1")], [
    html.small([], [
      html.text("This is an open-source project. Find it on "),
      html.a(
        [
          attr.href(
            "https://github.com/MissFahrenheit/improv-festivals-worldwide",
          ),
          attr.target("_blank"),
          attr.title("Improv Festivals Worldwide Project Github page"),
        ],
        [html.text("GitHub")],
      ),
      html.text(", fork it, go wild."),
    ]),
  ])
}

fn continent_tab_button(
  continent: Continent,
  model: types.Model,
) -> element.Element(types.Msg) {
  let active_class = case model.active_tab == continent.id {
    True -> "active"
    False -> ""
  }

  html.button(
    [
      attr.class("py-2 px-3 pill tab " <> active_class),
      attr.type_("button"),
      attr.data("continent", continent.id),
      event.on_click(types.UserClickedTab(continent.id)),
    ],
    [
      html.text(case string.contains(continent.label, "/") {
        False -> {
          case string.contains(continent.label, " ") {
            False -> string.capitalise(continent.label)
            True -> capitalize_string(continent.label, " ")
          }
        }
        True -> capitalize_string(continent.label, "/")
      }),
    ],
  )
}

fn capitalize_string(init_string: String, char: String) -> String {
  init_string
  |> string.split(char)
  |> list.map(string.capitalise)
  |> string.join(char)
}

fn model_to_json(
  active_tab: String,
  festivals: List(Festival),
  continents: List(Continent),
) -> String {
  json.object([
    #("active_tab", json.string(active_tab)),
    #("festivals", festivals_to_json(festivals)),
    #("continents", continents_to_json(continents)),
  ])
  |> json.to_string
}

fn festivals_to_json(festivals: List(Festival)) -> json.Json {
  json.array(festivals, festival_shared.festival_to_json)
}

fn continents_to_json(continents: List(Continent)) -> json.Json {
  json.array(continents, festival_shared.continent_to_json)
}
