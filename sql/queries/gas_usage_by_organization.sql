SELECT 
-- 	A.organization, 
	A.organization, A.address, 
	SUM(T.receipt_gas_used) AS total_gas_used, 
	COUNT(T.from_address) AS transactions_count,
	MIN(T.block_number) AS min_block_number,
	MAX(T.block_number) AS max_block_number,
	MIN(T.block_timestamp) AS min_timestamp,
	MAX(T.block_timestamp) AS max_timestamp
FROM public.accounts A
LEFT JOIN public.transactions T
	ON UPPER(A.address) = UPPER(T.from_address)
--WHERE
--	T.block_timestamp between 
--		'2001-02-16 20:38:40' and 
--		'2023-04-14 16:48:02'
--GROUP BY A.organization
GROUP BY A.organization, A.address
ORDER BY A.organization, total_gas_used ASC
