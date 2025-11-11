<%@ page import="java.sql.*" %>
<%@ include file="db_connection.jsp" %>

<%
    String book = request.getParameter("book");
    String quantity = request.getParameter("quantity");
    Integer userId = (Integer) session.getAttribute("user_id");
    
    if(userId != null && book != null && quantity != null) {
        try {
            // Get book ID from title
            PreparedStatement bookStmt = con.prepareStatement("SELECT id FROM books WHERE title=?");
            bookStmt.setString(1, book);
            ResultSet bookRs = bookStmt.executeQuery();
            
            if(bookRs.next()) {
                int bookId = bookRs.getInt("id");
                
                // Create order
                PreparedStatement pst = con.prepareStatement("INSERT INTO orders (user_id, book_id, quantity) VALUES (?, ?, ?)");
                pst.setInt(1, userId);
                pst.setInt(2, bookId);
                pst.setInt(3, Integer.parseInt(quantity));
                
                int result = pst.executeUpdate();
                if(result > 0) {
                    response.sendRedirect("order_success.jsp");
                } else {
                    response.sendRedirect("order.html?error=Order failed");
                }
            } else {
                response.sendRedirect("order.html?error=Book not found");
            }
        } catch(Exception e) {
            out.println("Error: " + e.getMessage());
        }
    } else {
        response.sendRedirect("LOGIN.html?error=Please login first");
    }
%>