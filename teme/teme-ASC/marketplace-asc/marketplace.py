"""
This module represents the Marketplace.

Computer Systems Architecture Course
Assignment 1
March 2021
"""
import threading
import logging
import unittest
from logging.handlers import RotatingFileHandler
from typing import List, Dict
from .product import OwnedProduct, Product

class Marketplace:
    """
    Class that represents the Marketplace. It's the central part of the implementation.
    The producers and consumers use its methods concurrently.
    """
    no_producers: int = 0
    no_consumers: int = 0
    carts: Dict[int, List[OwnedProduct]] = {}
    count_products: Dict[int, int] = {}
    producers_per_products: Dict[Product, List[int]] = {}
    lock = threading.Lock()

    def __init__(self, queue_size_per_producer):
        """
        Constructor

        :type queue_size_per_producer: Int
        :param queue_size_per_producer: the maximum size of a queue associated with each producer
        """
        self.queue_size_per_producer = queue_size_per_producer
        self.logger = logging.getLogger('Marketplace')
        self.logger.setLevel(logging.INFO)
        handler = RotatingFileHandler('marketplace.log', maxBytes=100000, backupCount=5)
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        handler.setFormatter(formatter)
        self.logger.addHandler(handler)

    def register_producer(self):
        """
        Returns an id for the producer that calls this.
        """
        self.no_producers += 1
        self.count_products[self.no_producers] = 0

        return self.no_producers

    def publish(self, producer_id, product):
        """
        Adds the product provided by the producer to the marketplace

        :type producer_id: String
        :param producer_id: producer id

        :type product: Product
        :param product: the Product that will be published in the Marketplace

        :returns True or False. If the caller receives False, it should wait and then try again.
        """
        self.logger.info("publish() method call with arguments: \
                         cart_id=%s product=%s", producer_id, product)
        if self.count_products[producer_id] >= self.queue_size_per_producer:
            return False

        if product not in self.producers_per_products:
            self.producers_per_products[product] = []

        check = False
        for producer in self.producers_per_products[product]:
            if producer == producer_id:
                check = True

        if not check:
            self.producers_per_products[product].append(producer_id)

        self.count_products[producer_id] += 1

        return True

    def new_cart(self):
        """
        Creates a new cart for the consumer

        :returns an int representing the cart_id
        """
        self.no_consumers += 1
        self.carts[self.no_consumers] = []

        return self.no_consumers

    def add_to_cart(self, cart_id, product):
        """
        Adds a product to the given cart. The method returns

        :type cart_id: Int
        :param cart_id: id cart

        :type product: Product
        :param product: the product to add to cart
        :returns True or False. If the caller receives False, it should wait and then try again
        """
        self.logger.info("add_to_cart() method call with arguments: \
                         cart_id=%s product=%s", cart_id, product)
        if product not in self.producers_per_products:
            return False

        if len(self.producers_per_products[product]) == 0:
            return False

        prod_id = self.producers_per_products[product][0]
        self.carts[cart_id].append(OwnedProduct(prod_id=prod_id, product=product))
        self.count_products[prod_id] -= 1

        return True

    def remove_from_cart(self, cart_id, product):
        """
        Removes a product from cart.

        :type cart_id: Int
        :param cart_id: id cart

        :type product: Product
        :param product: the product to remove from cart
        """
        self.logger.info("remove_from_cart() method call with \
                          arguments: cart_id=%s product=%s", cart_id, product)
        copy_cart = self.carts[cart_id]

        for item in copy_cart:
            if item.product == product:
                if self.count_products[item.prod_id] < self.queue_size_per_producer:
                    self.carts[cart_id].remove(item)
                    self.count_products[item.prod_id] += 1
                    return True

        return False

    def place_order(self, cart_id):
        """
        Return a list with all the products in the cart.

        :type cart_id: Int
        :param cart_id: id cart
        """
        self.logger.info("place_order() method call with arguments: cart_id=%s", cart_id)
        copy_cart = list(self.carts[cart_id])

        self.carts[cart_id].clear()

        return copy_cart

class TestMarketplace(unittest.TestCase):
    """
    Classed used for testing Marketplace methods.
    """
    MOCK_QUEUE_SIZE = 12
    PRODUCT = Product(name='test', price=10)
    PRODUCER_ID = 1
    ALL_PRODUCTS = {PRODUCT: [1]}
    COUNTED_PRODUCTS = {1: 1}

    def setUp(self):
        """
        Method used to initialize a mock Marketplace for testing.
        """
        self.marketplace = Marketplace(self.MOCK_QUEUE_SIZE)
        self.producer_id = 0
        self.consumer_id = 0

    def test_register_producer(self):
        """
        Method used for testing the register_producer method.
        """
        initial_no_producers = self.marketplace.no_producers
        self.marketplace.register_producer()
        self.assertEqual(self.marketplace.no_producers, initial_no_producers + 1)
        self.assertEqual(self.marketplace.count_products[self.marketplace.no_producers], 0)

    def test_publish_success(self):
        """
        Method used for testing the publish method when succesful.
        """
        self.producer_id = self.marketplace.register_producer()

        result = self.marketplace.publish(producer_id=self.PRODUCER_ID, product=self.PRODUCT)

        self.assertTrue(result)

        self.assertEqual(self.marketplace.count_products[self.PRODUCER_ID], 1)
        self.assertEqual(self.marketplace.producers_per_products[self.PRODUCT], [self.PRODUCER_ID])

    def test_publish_failure(self):
        """
        Method used for testing the publish method when failing.
        """
        self.marketplace.count_products = {1: 15}

        result = self.marketplace.publish(producer_id=self.PRODUCER_ID, product=self.PRODUCT)

        self.assertFalse(result)

    def test_new_cart(self):
        """
        Method used for testing the new_cart method.
        """
        initial_no_consumers = self.marketplace.no_consumers
        self.marketplace.new_cart()
        self.assertEqual(self.marketplace.no_consumers, initial_no_consumers + 1)
        self.assertEqual(self.marketplace.carts[self.marketplace.no_consumers], [])

    def test_add_to_cart_no_products(self):
        """
        Method used for testing the add_to_cart method when there are no products.
        """
        self.marketplace.producers_per_products = {}

        result = self.marketplace.add_to_cart(cart_id=1, product=self.PRODUCT)

        self.assertFalse(result)

    def test_add_to_cart_success(self):
        """
        Method used for testing the add_to_cart method when successful.
        """
        self.marketplace.count_products = self.COUNTED_PRODUCTS
        self.marketplace.producers_per_products = self.ALL_PRODUCTS
        self.marketplace.carts[1] = []

        result = self.marketplace.add_to_cart(cart_id=1, product=self.PRODUCT)

        self.assertTrue(result)

    def test_remove_from_cart_success(self):
        """
        Method used for testing the remove_from_cart method when successful.
        """
        self.marketplace.count_products = self.COUNTED_PRODUCTS
        self.marketplace.producers_per_products = self.ALL_PRODUCTS
        self.marketplace.carts[1] = [OwnedProduct(prod_id=1, product=self.PRODUCT)]

        result = self.marketplace.remove_from_cart(cart_id=1, product=self.PRODUCT)

        self.assertTrue(result)

    def test_place_order(self):
        """
        Method used for testing the place_order method.
        """
        self.marketplace.carts[1] = [OwnedProduct(prod_id=1, product=self.PRODUCT)]

        result = self.marketplace.place_order(cart_id=1)

        self.assertEqual(result, [OwnedProduct(prod_id=1, product=self.PRODUCT)])
    