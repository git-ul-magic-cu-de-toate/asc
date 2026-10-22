"""
This module represents the Consumer.

Computer Systems Architecture Course
Assignment 1
March 2021
"""

from threading import Thread
import time

class Consumer(Thread):
    """
    Class that represents a consumer.
    """
    id_cons: int

    def __init__(self, carts, marketplace, retry_wait_time, **kwargs):
        """
        Constructor.

        :type carts: List
        :param carts: a list of add and remove operations

        :type marketplace: Marketplace
        :param marketplace: a reference to the marketplace

        :type retry_wait_time: Time
        :param retry_wait_time: the number of seconds that a producer must wait
        until the Marketplace becomes available

        :type kwargs:
        :param kwargs: other arguments that are passed to the Thread's __init__()
        """
        self.carts = carts
        self.marketplace = marketplace
        self.retry_wait_time = retry_wait_time
        super().__init__(**kwargs)

    def run(self):
        self.id_cons = self.marketplace.new_cart()
        for cart in self.carts:
            for order_step in cart:
                # add the quantity of products from the input order
                if order_step["type"] == "add":
                    quantity = 0

                    while quantity < order_step["quantity"]:
                        with self.marketplace.lock:
                            if self.marketplace.add_to_cart(self.id_cons, order_step["product"]):
                                quantity += 1

                        # retry if there are not any products available
                        if quantity < order_step["quantity"]:
                            time.sleep(self.retry_wait_time)

                # remove the quantity of products from the input order
                elif order_step["type"] == "remove":
                    quantity = 0

                    while quantity < order_step["quantity"]:
                        with self.marketplace.lock:
                            prod = order_step["product"]
                            if self.marketplace.remove_from_cart(self.id_cons, prod):
                                quantity += 1

                        # retry if there are not any products available
                        if quantity < order_step["quantity"]:
                            time.sleep(self.retry_wait_time)

            products = self.marketplace.place_order(self.id_cons)

            for item in products:
                print(f"{self.name} bought {item.product}")
