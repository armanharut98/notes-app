describe("Notes app", function () {
  beforeEach(function () {
    cy.request("POST", `${Cypress.env("BACKEND")}/testing/reset`)
    cy.request("POST", `${Cypress.env("BACKEND")}/users`, {
      name: "Matti Luukkainen",
      username: "mluukkai",
      password: "salainen"
    })
    cy.visit("")
  })

  it("front page can be opened", function () {
    cy.contains("Notes")
    cy.contains('Note app, Department of Computer Science, University of Helsinki 2024')
  })

  it("login form can be opened", function () {
    cy.contains("login").click()
  })

  it("user can log in", function () {
    cy.contains("login").click()
    cy.get(".togglableContent").not("have.css", "display: none")
    cy.get("#username").type("mluukkai")
    cy.get("#password").type("salainen")
    cy.get("#login-button").click()
    cy.contains("Matti Luukkainen logged in")
  })

  it("login fails with wrong password", function () {
    cy.contains('login').click()
    cy.get('#username').type('mluukkai')
    cy.get('#password').type('wrong')
    cy.get('#login-button').click()
    cy.get('.error')
      .should('contain', 'Wrong Credentials')
      .and('have.css', 'color', 'rgb(255, 0, 0)')
      .and('have.css', 'border-style', 'solid')

    cy.get("html")
      .should("not.contain", "Matti Luukkainen logged in")
  })

  describe("when logged in", function () {
    beforeEach(function () {
      cy.login({ username: "mluukkai", password: "salainen" })
    })

    it("a new note can be created", function () {
      cy.contains("create").click()
      cy.get("#new-note").type("cypress note")
      cy.contains("save").click()
      cy.contains("cypress note")
    })
    describe("and several notes exists", function () {
      beforeEach(function () {
        cy.createNote({ content: "first note", important: false })
        cy.createNote({ content: "second note", important: false })
        cy.createNote({ content: "third note", important: false })
      })

      it("one of those can be made important", function () {
        cy.contains("second note").parent().find("button").as("importantButton")
        cy.get("@importantButton").click()
        cy.get("@importantButton").should("contain", "make not important")
      })
    })
  })
})