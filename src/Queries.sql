use dbpp;

-- 1.Find users with religion islam and performed transection
    SELECT 
    u.user_id, 
    u.first_name, 
    u.last_name, 
    p.religion 
FROM
    User as u
INNER JOIN 
    Profile as p ON u.user_id = p.user_id
INNER JOIN 
    Subscription as s ON u.subscription_id = s.subscription_id
INNER JOIN 
    Subscription_details as sd ON s.subscription_id = sd.subscription_id
INNER JOIN 
    Transaction as t ON sd.transaction_id = t.transaction_id
WHERE 
    p.religion = 'Islam'
GROUP BY 
    u.user_id, u.first_name, u.last_name, p.religion;
    
    
    -- 2.users and their subscriptions, along with transaction details and preferences.
    SELECT 
    u.user_id, 
    u.first_name, 
    s.subscription_plan, 
    t.amount AS transaction_amount, 
    p.country AS preferred_country
FROM 
    User AS u
INNER JOIN 
    Subscription AS s ON u.subscription_id = s.subscription_id
INNER JOIN 
    Subscription_details AS sd ON s.subscription_id = sd.subscription_id
INNER JOIN 
    Transaction AS t ON sd.transaction_id = t.transaction_id
INNER JOIN 
    Preference AS p ON u.preference_id = p.preference_id;
    
    
    -- 3.Retrieve all users and match requests they’ve sent or received, including users without requests.
    SELECT 
    u.user_id, 
    u.first_name, 
    mr.request_id, 
    mr.message, 
    sender.first_name AS sender_name, 
    receiver.first_name AS receiver_name
FROM 
    User AS u
LEFT JOIN 
    Match_request AS mr ON u.user_id = mr.sender_id OR u.user_id = mr.receiver_id
LEFT JOIN 
    User AS sender ON mr.sender_id = sender.user_id
LEFT JOIN 
    User AS receiver ON mr.receiver_id = receiver.user_id;
    
    -- 4.List all transactions and users who made them, ensuring no transactions are missed.
    SELECT 
    t.transaction_id, 
    t.amount, 
    u.user_id, 
    u.first_name
FROM 
    Transaction AS t
RIGHT JOIN 
    Subscription_details AS sd ON t.transaction_id = sd.transaction_id
RIGHT JOIN 
    Subscription AS s ON sd.subscription_id = s.subscription_id
RIGHT JOIN 
    User AS u ON s.subscription_id = u.subscription_id;


-- 5 Retrieve all match requests, their senders, receivers, and associated profiles.
SELECT 
    mr.request_id, 
    sender.first_name AS sender_name, 
    receiver.first_name AS receiver_name, 
    sender_p.country AS sender_country, 
    receiver_p.religion AS receiver_religion
FROM 
    Match_request AS mr
JOIN 
    User AS sender ON mr.sender_id = sender.user_id
JOIN 
    Profile AS sender_p ON sender.user_id = sender_p.user_id
JOIN 
    User AS receiver ON mr.receiver_id = receiver.user_id
JOIN 
    Profile AS receiver_p ON receiver.user_id = receiver_p.user_id;



-- 6 Fetch completed matches, the feedback given, and the profiles of both users in the match.
SELECT 
    cm.couple_id, 
    cm.match_date, 
    f.rating_star, 
    sender.first_name AS sender_name, 
    receiver.first_name AS receiver_name
FROM 
    Completed_match AS cm
INNER JOIN 
    Match_request AS mr ON cm.match_id = mr.request_id
INNER JOIN 
    Feedback AS f ON cm.couple_id = f.couple_id
LEFT JOIN 
    User AS sender ON mr.sender_id = sender.user_id
LEFT JOIN 
    User AS receiver ON mr.receiver_id = receiver.user_id;
    
    -- 7 List all consultants and the queries they’ve handled, ensuring consultants without queries are included.
    SELECT 
    c.consultant_id, 
    c.first_name AS consultant_name, 
    sf.query AS user_query, 
    u.first_name AS user_name
FROM 
    Consultant AS c
LEFT JOIN 
    Support_FAQs AS sf ON c.consultant_id = sf.consultant_id
LEFT JOIN 
    User AS u ON sf.user_id = u.user_id;
    
    -- 8 Retrieve all users, their preferences, and any feedback they’ve provided.
    SELECT 
    u.user_id, 
    u.first_name, 
    p.religion, 
    f.rating_star, 
    f.comments
FROM 
    User AS u
LEFT JOIN 
    Preference AS p ON u.preference_id = p.preference_id
LEFT JOIN 
    Completed_match AS cm ON u.user_id = cm.match_id
LEFT JOIN 
    Feedback AS f ON cm.couple_id = f.couple_id;


-- 9 Retrieve match requests with sender, receiver details, and their subscriptions
SELECT 
    mr.request_id, 
    sender.first_name AS sender_name, 
    receiver.first_name AS receiver_name, 
    sender_sub.subscription_plan AS sender_subscription, 
    receiver_sub.subscription_plan AS receiver_subscription
FROM 
    Match_request AS mr
LEFT JOIN 
    User AS sender ON mr.sender_id = sender.user_id
LEFT JOIN 
    User AS receiver ON mr.receiver_id = receiver.user_id
LEFT JOIN 
    Subscription AS sender_sub ON sender.subscription_id = sender_sub.subscription_id
LEFT JOIN 
    Subscription AS receiver_sub ON receiver.subscription_id = receiver_sub.subscription_id;
    
    -- 10 List FAQs with linked users, consultants, and their transactions
    SELECT 
    sf.faq_id, 
    sf.query AS faq_query, 
    u.first_name AS user_name, 
    c.first_name AS consultant_name, 
    t.amount AS transaction_amount
FROM 
    Support_FAQs AS sf
INNER JOIN 
    User AS u ON sf.user_id = u.user_id
INNER JOIN 
    Consultant AS c ON sf.consultant_id = c.consultant_id
INNER JOIN 
    Subscription_details AS sd ON u.subscription_id = sd.subscription_id
INNER JOIN 
    Transaction AS t ON sd.transaction_id = t.transaction_id;
    
    -- 11etrieve users who have transactions associated with subscriptions expiring on the latest expiration date
    SELECT user_id, first_name, last_name 
FROM User 
WHERE subscription_id IN (
    SELECT subscription_id 
    FROM Subscription 
    WHERE expire_date = (
        SELECT MAX(expire_date) 
        FROM Subscription
    )
    AND subscription_id IN (
        SELECT subscription_id 
        FROM Subscription_details 
        WHERE transaction_id IN (
            SELECT transaction_id 
            FROM Transaction
        )
    )
);

-- 12 Find users whose profiles include the same religion and country as the preferences set in their subscription plan
SELECT user_id, first_name, last_name 
FROM User 
WHERE user_id IN (
    SELECT user_id 
    FROM Profile 
    WHERE religion IN (
        SELECT religion 
        FROM Preference 
        WHERE preference_id = User.preference_id
    )
    AND country IN (
        SELECT country 
        FROM Preference 
        WHERE preference_id = User.preference_id
    )
);


-- 13 Retrieve profiles for users who received match requests from users in the same city.
SELECT profile_id, bio 
FROM Profile 
WHERE user_id IN (
    SELECT receiver_id 
    FROM Match_request 
    WHERE sender_id IN (
        SELECT user_id 
        FROM Profile 
        WHERE city = (
            SELECT city 
            FROM Profile 
            WHERE user_id = Match_request.receiver_id
        )
    )
);

-- 14 Find all completed matches where the feedback rating is greater than the average rating for all couples
SELECT couple_id, match_date 
FROM Completed_match 
WHERE couple_id IN (
    SELECT couple_id 
    FROM Feedback 
    WHERE rating_star > (
        SELECT AVG(rating_star) 
        FROM Feedback
    )
);

-- 15 Retrieve users who have received a notification on the same day as their subscription start date
SELECT user_id, first_name, last_name 
FROM User 
WHERE notification_id IN (
    SELECT notification_id 
    FROM Notification 
    WHERE date IN (
        SELECT start_date 
        FROM Subscription 
        WHERE subscription_id = User.subscription_id
    )
);


-- 16Find users whose preferences include countries where their profiles do not exist
SELECT user_id, first_name, last_name 
FROM User 
WHERE preference_id IN (
    SELECT preference_id 
    FROM Preference 
    WHERE country NOT IN (
        SELECT country 
        FROM Profile 
        WHERE user_id = User.user_id
    )
);

-- 17 Retrieve profiles where the income is greater than the average income of users with the same religion
SELECT profile_id, income 
FROM Profile 
WHERE income > (
    SELECT AVG(income) 
    FROM Profile AS p2 
    WHERE p2.religion = Profile.religion
);



-- 18 Retrieve users whose profiles and preferences have a mismatch in education.
SELECT user_id, first_name, last_name 
FROM User 
WHERE preference_id IN (
    SELECT preference_id 
    FROM Preference 
    WHERE education NOT IN (
        SELECT education 
        FROM Profile 
        WHERE user_id = User.user_id
    )
);


-- 19  Find users whose subscription transactions were processed in the same month as their notification date 
SELECT user_id, first_name, last_name 
FROM User 
WHERE subscription_id IN (
    SELECT subscription_id 
    FROM Subscription_details 
    WHERE transaction_id IN (
        SELECT transaction_id 
        FROM Transaction 
        WHERE MONTH(date) IN (
            SELECT MONTH(date) 
            FROM Notification 
            WHERE notification_id = User.notification_id
        )
    )
);

-- 20 Find users who have not received any match requests but have completed transactions for subscriptions.
SELECT user_id, first_name, last_name 
FROM User 
WHERE user_id NOT IN (
    SELECT sender_id 
    FROM Match_request
)
AND subscription_id IN (
    SELECT subscription_id 
    FROM Subscription_details 
    WHERE transaction_id IN (
        SELECT transaction_id 
        FROM Transaction
    )
);


-- 21 Retrieve profiles of users who have received a match request but do not have feedback for completed matches.
SELECT profile_id, bio 
FROM Profile 
WHERE user_id IN (
    SELECT receiver_id 
    FROM Match_request
)
AND user_id NOT IN (
    SELECT user_id 
    FROM User 
    WHERE user_id IN (
        SELECT couple_id 
        FROM Feedback
    )
);
 
    
