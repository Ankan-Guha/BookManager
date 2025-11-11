<%@ page import='java.util.*, com.bookwebsite.model.Book' %>
    <jsp:useBean id='bookList' class='java.util.ArrayList' scope='request' />
    <html>

    <body>
        <h1>Book Catalog</h1>
        <ul>
            <% for (Book b : (List<Book>)request.getAttribute("books")) { %><li>
                    <%= b.getTitle() %> - $<%= b.getPrice() %>
                </li>
                <% } %>
        </ul>
    </body>

    </html>